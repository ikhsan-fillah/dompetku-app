import 'dart:math' as math;

import 'package:get/get.dart';

import '../../../core/state/resource_state.dart';
import '../data/stock_repository.dart';
import '../models/broker_group.dart';
import '../models/broker_range_row.dart';
import '../models/daily_bar.dart';
import '../models/ml_cycle.dart';
import '../models/ml_prediction.dart';
import '../models/news_score.dart';
import '../models/price_point.dart';
import '../services/broker_flow_analysis.dart';
import '../services/broker_group_calculator.dart';
import '../services/risk_analysis.dart';
import '../services/risk_inputs.dart';

/// Data satu saham: baris per broker dan aturan kelompok.
class StockDetailData {
  const StockDetailData({required this.rows, required this.rules});

  final List<BrokerRangeRow> rows;
  final BrokerGroupRules rules;
}

/// Empat tab halaman detail: arus dana broker, chart dengan indikator,
/// prediksi model ML, dan risiko (gerak harga dan ukuran posisi).
enum DetailTab { broker, chart, ml, risk }

/// Berapa hari perdagangan yang diambil dari Supabase untuk tab Chart. Tab
/// hanya menggambar satu bulan terakhir; sisanya cadangan bila ada hari
/// yang ditandai tidak akurat.
const chartFetchLimit = 40;

/// Hari bursa yang diambil dari `price_history`: cukup untuk MA200 dan
/// volatilitas setahun.
const historyFetchLimit = 260;

/// Hari bursa yang diambil untuk tab Risiko: seluruh riwayat (sekitar lima
/// tahun), karena frekuensi sentuh CL butuh banyak jendela 10 hari.
const riskFetchLimit = 1400;

/// Jumlah prediksi terakhir yang ditampilkan di riwayat.
const predictionHistoryLimit = 10;

/// Kode IHSG di `price_history`, dipakai untuk sentimen pasar.
const marketIndexTicker = '^JKSE';

/// Berapa broker yang ditampilkan di tiap daftar teratas.
const topBrokerCount = 5;

/// Tampilan satu saham: arus dana per broker dengan total kelompok yang
/// dihitung di app, serta chart harga dan indikator.
class StockDetailController extends GetxController {
  StockDetailController(
    this._repository,
    this.ticker, {
    BrokerGroupCalculator calculator = const BrokerGroupCalculator(),
    RiskPrefs riskPrefs = const RiskPrefs(),
  }) : _calculator = calculator,
       _riskPrefs = riskPrefs;

  final StockRepository _repository;
  final BrokerGroupCalculator _calculator;
  final RiskPrefs _riskPrefs;
  final String ticker;

  final state = const ResourceState<StockDetailData>.idle().obs;
  final bars = const ResourceState<List<DailyBar>>.idle().obs;
  final range = brokerRangeLabels.first.obs;
  final tab = DetailTab.broker.obs;

  /// Hari yang disentuh di chart (indeks di [visibleBars]), null berarti
  /// hari terakhir. Blok tinta menampilkan hari ini selama tab Chart aktif.
  final chartIndex = RxnInt();

  /// Prediksi ML terbaru saham ini. Kosong bila model belum menilainya.
  final ml = const ResourceState<MlPrediction>.idle().obs;

  /// Prediksi lama yang hasil nyatanya sudah dihitung, null bila belum ada.
  final mlMatured = Rxn<MlPrediction>();

  /// Riwayat prediksi saham ini dari model aktif, terbaru dulu. Tiap prediksi
  /// punya jendela 10 hari yang tetap sejak tanggal sinyalnya. Kosong bila
  /// belum ada atau gagal dimuat.
  final mlHistory = <MlPrediction>[].obs;

  /// Siklus 10 hari bursa saham ini, terbaru dulu. Kosong bila belum ada
  /// siklus atau gagal dimuat; tab lalu memakai prediksi harian seperti biasa.
  final mlCycles = <MlCycle>[].obs;

  /// Riwayat harga saham ini dan IHSG dari `price_history`, terlama dulu.
  /// Kosong bila gagal dimuat; bagian yang memakainya lalu disembunyikan.
  final history = <PricePoint>[].obs;
  final marketHistory = <PricePoint>[].obs;

  /// Skor kata berita pasar pada hari bursa terakhir IHSG, null bila belum
  /// ada atau gagal dimuat.
  final newsScore = Rxn<NewsScore>();

  /// Ukuran gerak harga dan frekuensi sentuh CL untuk tab Risiko. Dimuat
  /// saat tab pertama kali dibuka. Kosong bila riwayat terlalu pendek.
  final risk = const ResourceState<RiskAnalysis>.idle().obs;

  /// Modal, batas rugi, dan CL untuk hitung ukuran posisi.
  final riskInputs = const RiskInputs().obs;

  BrokerFlowAnalysis? _analysis;
  StockDetailData? _analysisSource;

  /// Analisis aliran dana lintas rentang, dihitung sekali per data broker.
  BrokerFlowAnalysis? get analysis {
    final source = data;
    if (source == null) return null;
    if (!identical(source, _analysisSource)) {
      _analysis = BrokerFlowAnalysis(source.rows, source.rules);
      _analysisSource = source;
    }
    return _analysis;
  }

  StockDetailData? get data => state.value.data;

  /// Hari perdagangan yang digambar: satu bulan kalender terakhir sampai
  /// hari terakhir yang ada, terlama dulu.
  List<DailyBar> get visibleBars => lastMonth(bars.value.data ?? const []);

  /// Hari terakhir yang punya data, null bila tabel harga masih kosong.
  DailyBar? get latestBar => bars.value.data?.lastOrNull;

  /// Hari yang tampil di blok tinta: hari yang disentuh di chart bila tab
  /// Chart aktif, selain itu hari terakhir.
  DailyBar? get heroBar {
    final index = chartIndex.value;
    if (tab.value == DetailTab.chart && index != null) {
      final visible = visibleBars;
      if (index >= 0 && index < visible.length) return visible[index];
    }
    return latestBar;
  }

  /// True bila blok tinta sedang menampilkan hari lain dari hari terakhir.
  bool get showingPastDay => heroBar != latestBar;

  /// Baris rentang terpilih: net beli dulu, tiap sisi dari nilai terbesar.
  List<BrokerRangeRow> get rowsInRange {
    final rows = [
      for (final row in data?.rows ?? const <BrokerRangeRow>[])
        if (row.rangeLabel == range.value) row,
    ];
    rows.sort((a, b) {
      if (a.side != b.side) return a.side == BrokerSide.buy ? -1 : 1;
      return b.valueIdr.compareTo(a.valueIdr);
    });
    return rows;
  }

  List<BrokerRangeRow> _side(BrokerSide side) => [
    for (final row in rowsInRange)
      if (row.side == side) row,
  ];

  /// Seluruh broker net beli pada rentang terpilih, terbesar dulu.
  List<BrokerRangeRow> get buyers => _side(BrokerSide.buy);

  /// Seluruh broker net jual pada rentang terpilih, terbesar dulu.
  List<BrokerRangeRow> get sellers => _side(BrokerSide.sell);

  List<BrokerRangeRow> get topBuyers => buyers.take(topBrokerCount).toList();

  List<BrokerRangeRow> get topSellers => sellers.take(topBrokerCount).toList();

  GroupSummary get summary => _calculator.summarize(
    rowsInRange,
    data?.rules ?? const BrokerGroupRules.empty(),
  );

  /// Tanggal awal dan akhir rentang terpilih, null bila tidak ada data.
  (DateTime, DateTime)? get period {
    final rows = rowsInRange;
    if (rows.isEmpty) return null;
    return (rows.first.rangeStart, rows.first.rangeEnd);
  }

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Memuat data broker dan data harga bersamaan. Keduanya gagal sendiri-
  /// sendiri, jadi chart tetap tampil bila data broker bermasalah.
  Future<void> load() =>
      Future.wait([loadBrokers(), loadBars(), loadMl(), loadHistory()]);

  Future<void> loadBrokers() async {
    state.value = const ResourceState.loading();
    try {
      final results = await Future.wait([
        _repository.getLatestBrokerRanges(ticker),
        _repository.getBrokerGroupRules(),
      ]);
      final rows = results[0] as List<BrokerRangeRow>;
      final rules = results[1] as BrokerGroupRules;
      state.value = rows.isEmpty
          ? const ResourceState.empty()
          : ResourceState.success(StockDetailData(rows: rows, rules: rules));
    } catch (_) {
      state.value = ResourceState.error('Gagal memuat data broker.'.tr);
    }
  }

  Future<void> loadBars() async {
    bars.value = const ResourceState.loading();
    chartIndex.value = null;
    try {
      final rows = await _repository.getRecentBars(
        ticker,
        limit: chartFetchLimit,
      );
      bars.value = rows.isEmpty
          ? const ResourceState.empty()
          : ResourceState.success(rows);
    } catch (_) {
      bars.value = ResourceState.error('Gagal memuat data harga.'.tr);
    }
  }

  Future<void> loadMl() async {
    ml.value = const ResourceState.loading();
    try {
      final matured = _latestMatured();
      final past = _predictionHistory();
      final cycles = _cycleHistory();
      final prediction = await _repository.getLatestPrediction(ticker);
      mlMatured.value = await matured;
      mlHistory.assignAll(await past);
      mlCycles.assignAll(await cycles);
      // Siklus aktif menentukan prediksi yang dibaca: tanggal sinyalnya tetap,
      // tidak ikut bergeser ke prediksi harian terbaru.
      final current = mlCycles.firstOrNull;
      final shown = current == null
          ? prediction
          : await _cyclePrediction(current) ?? current.toPrediction();
      ml.value = shown == null
          ? const ResourceState.empty()
          : ResourceState.success(shown);
    } catch (_) {
      ml.value = ResourceState.error('Gagal memuat prediksi ML.'.tr);
    }
  }

  /// Riwayat harga bersifat tambahan: bila gagal, tab tetap tampil tanpa
  /// tren, support, resistance, dan sentimen.
  Future<void> loadHistory() async {
    Future<List<PricePoint>> safe(String code) async {
      try {
        return await _repository.getPriceHistory(
          code,
          limit: historyFetchLimit,
        );
      } catch (_) {
        return const [];
      }
    }

    final results = await Future.wait([safe(ticker), safe(marketIndexTicker)]);
    history.assignAll(results[0]);
    marketHistory.assignAll(results[1]);
    final day = results[1].lastOrNull?.date;
    if (day == null) return;
    try {
      newsScore.value = await _repository.getNewsScore(day);
    } catch (_) {
      newsScore.value = null;
    }
  }

  /// Hasil nyata bersifat tambahan: bila gagal dimuat, tab tetap tampil.
  Future<MlPrediction?> _latestMatured() async {
    try {
      return await _repository.getLatestMaturedPrediction(ticker);
    } catch (_) {
      return null;
    }
  }

  /// Riwayat bersifat tambahan: bila gagal dimuat, kartu tetap tampil.
  Future<List<MlPrediction>> _predictionHistory() async {
    try {
      return await _repository.getPredictionHistory(
        ticker,
        limit: predictionHistoryLimit,
      );
    } catch (_) {
      return const [];
    }
  }

  /// Siklus bersifat tambahan: bila gagal dimuat (misalnya tabel belum ada),
  /// tab tetap tampil dengan prediksi harian.
  Future<List<MlCycle>> _cycleHistory() async {
    try {
      return await _repository.getCycleHistory(
        ticker,
        limit: predictionHistoryLimit,
      );
    } catch (_) {
      return const [];
    }
  }

  /// Baris `ml_prediction` pada tanggal sinyal siklus (lengkap dengan faktor
  /// dan uji balik model), null bila tidak ada atau gagal dimuat.
  Future<MlPrediction?> _cyclePrediction(MlCycle cycle) async {
    try {
      return await _repository.getPredictionOn(
        ticker,
        cycle.cycleStart,
        cycle.tenDay.model,
      );
    } catch (_) {
      return null;
    }
  }

  void selectRange(String label) => range.value = label;

  void selectTab(DetailTab value) {
    tab.value = value;
    if (value == DetailTab.risk && risk.value.status == ResourceStatus.idle) {
      loadRisk();
    }
  }

  /// Memuat seluruh riwayat harga dan isian ukuran posisi. Isian yang gagal
  /// dibaca diganti angka contoh, jadi hanya gagal memuat harga yang
  /// ditampilkan sebagai galat.
  Future<void> loadRisk() async {
    risk.value = const ResourceState.loading();
    final inputs = _riskPrefs.load();
    try {
      final points = await _repository.getPriceHistory(
        ticker,
        limit: riskFetchLimit,
      );
      riskInputs.value = await inputs;
      final analysis = RiskAnalysis.from(points);
      risk.value = analysis == null
          ? const ResourceState.empty()
          : ResourceState.success(analysis);
    } catch (_) {
      risk.value = ResourceState.error('Gagal memuat riwayat harga.'.tr);
    }
  }

  /// Menyimpan isian ukuran posisi dan langsung memakainya.
  Future<void> saveRiskInputs(RiskInputs value) async {
    riskInputs.value = value;
    await _riskPrefs.save(value);
  }

  void selectChartDay(int? index) => chartIndex.value = index;
}

/// Hari setelah tanggal yang sama sebulan sebelum hari terakhir. Untuk hari
/// terakhir 30/10 hasilnya 01/10 sampai 30/10. [oldestFirst] urut terlama dulu.
List<DailyBar> lastMonth(List<DailyBar> oldestFirst) {
  final last = oldestFirst.lastOrNull?.tradeDate;
  if (last == null) return const [];
  // Mundur satu bulan kalender. Tanggal dijepit ke akhir bulan sebelumnya
  // (31 Okt menjadi 30 Sep), karena DateTime(2026, 9, 31) bergeser ke 1 Okt.
  final month = DateTime(last.year, last.month - 1);
  final monthEnd = DateTime(month.year, month.month + 1, 0).day;
  final cutoff = DateTime(
    month.year,
    month.month,
    math.min(last.day, monthEnd),
  );
  return [
    for (final bar in oldestFirst)
      if (bar.tradeDate.isAfter(cutoff)) bar,
  ];
}
