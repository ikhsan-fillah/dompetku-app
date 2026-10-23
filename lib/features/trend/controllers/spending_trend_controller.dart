import 'package:get/get.dart';

import '../../../core/services/data_refresh_service.dart';
import '../../transaction/repositories/transaction_repository.dart';
import '../models/monthly_trend.dart';
import '../services/monthly_trend_service.dart';

/// Kartu Tren pengeluaran di Beranda: satu bulan, batang per hari. Bulan
/// dipilih dengan panah; hanya bulan yang punya transaksi (dan bulan ini) yang
/// bisa dikunjungi, dan tidak ada bulan depan.
class SpendingTrendController extends GetxController {
  SpendingTrendController(
    this._transactions, {
    MonthlyTrendService service = const MonthlyTrendService(),
    DateTime Function()? clock,
  }) : _service = service,
       _clock = clock ?? DateTime.now;

  final TransactionRepository _transactions;
  final MonthlyTrendService _service;
  final DateTime Function() _clock;

  final months = <DateTime>[].obs;
  late final month = MonthlyTrendService.monthOf(_clock()).obs;
  final trend = Rxn<MonthlyTrend>();

  /// Indeks hari yang sedang dipilih (diketuk), atau null.
  final selectedDay = RxnInt();
  final failed = false.obs;

  Worker? _refreshWorker;

  @override
  void onInit() {
    super.onInit();
    load();
    if (Get.isRegistered<DataRefreshService>()) {
      _refreshWorker = ever<int>(
        Get.find<DataRefreshService>().version,
        (_) => load(),
      );
    }
  }

  @override
  void onClose() {
    _refreshWorker?.dispose();
    super.onClose();
  }

  /// Memuat daftar bulan (yang punya transaksi, ditambah bulan ini) dan data
  /// bulan terpilih. Yang dibaca dari database hanya satu bulan itu, bukan
  /// seluruh transaksi.
  Future<void> load() async {
    try {
      final now = _clock();
      final current = MonthlyTrendService.monthOf(now);
      final first = await _transactions.firstTransactionDate();
      final withData = <DateTime>[];
      for (final candidate in _service.candidateMonths(first, now: now)) {
        if (candidate == current ||
            await _transactions.count(
                  range: MonthlyTrendService.monthRange(candidate),
                ) >
                0) {
          withData.add(candidate);
        }
      }
      months.assignAll(withData);
      if (!months.contains(month.value)) month.value = months.last;
      await _loadMonth();
      failed.value = false;
    } catch (_) {
      failed.value = true;
    }
  }

  int get _index => months.indexOf(month.value);

  bool get canGoPrevious => _index > 0;

  bool get canGoNext => _index >= 0 && _index < months.length - 1;

  Future<void> previousMonth() async {
    if (canGoPrevious) await _moveTo(months[_index - 1]);
  }

  Future<void> nextMonth() async {
    if (canGoNext) await _moveTo(months[_index + 1]);
  }

  Future<void> _moveTo(DateTime target) async {
    month.value = target;
    selectedDay.value = null;
    try {
      await _loadMonth();
      failed.value = false;
    } catch (_) {
      failed.value = true;
    }
  }

  /// Mengetuk batang memilihnya; mengetuk lagi atau hari yang belum berjalan
  /// melepas pilihan.
  void selectDay(int index) {
    final current = trend.value;
    if (current == null) return;
    if (index == selectedDay.value || index >= current.elapsedDays) {
      selectedDay.value = null;
      return;
    }
    selectedDay.value = index;
  }

  Future<void> _loadMonth() async {
    final transactions = await _transactions.getAll(
      range: MonthlyTrendService.monthRange(month.value),
    );
    trend.value = _service.build(transactions, month.value, now: _clock());
    final selected = selectedDay.value;
    if (selected != null && selected >= trend.value!.elapsedDays) {
      selectedDay.value = null;
    }
  }
}
