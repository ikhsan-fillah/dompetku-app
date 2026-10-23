import 'package:get/get.dart';

import '../../../core/services/data_refresh_service.dart';
import '../../transaction/models/transaction_model.dart';
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

  List<TransactionModel> _all = const [];

  Future<void> load() async {
    try {
      final all = await _transactions.getAll();
      _all = all;
      months.assignAll(_service.availableMonths(all, now: _clock()));
      if (!months.contains(month.value)) month.value = months.last;
      failed.value = false;
      _recompute();
    } catch (_) {
      failed.value = true;
    }
  }

  int get _index => months.indexOf(month.value);

  bool get canGoPrevious => _index > 0;

  bool get canGoNext => _index >= 0 && _index < months.length - 1;

  void previousMonth() {
    if (canGoPrevious) _moveTo(months[_index - 1]);
  }

  void nextMonth() {
    if (canGoNext) _moveTo(months[_index + 1]);
  }

  void _moveTo(DateTime target) {
    month.value = target;
    selectedDay.value = null;
    _recompute();
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

  void _recompute() {
    trend.value = _service.build(_all, month.value, now: _clock());
    final selected = selectedDay.value;
    if (selected != null && selected >= trend.value!.elapsedDays) {
      selectedDay.value = null;
    }
  }
}
