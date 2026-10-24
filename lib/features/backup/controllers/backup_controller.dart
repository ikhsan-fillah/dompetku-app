import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/database/database_constants.dart';
import '../../../core/services/data_refresh_service.dart';
import '../../../core/services/shared_prefs_service.dart';
import '../../../core/utils/date_range.dart';
import '../../budget/repositories/budget_repository.dart';
import '../../category/repositories/category_repository.dart';
import '../../recurring/services/recurring_reminders.dart';
import '../../transaction/repositories/transaction_repository.dart';
import '../../widget/home_widget_service.dart';
import '../services/backup_service.dart';
import '../services/excel_export.dart';

/// Halaman Cadangan data: buat cadangan .tally, pulihkan, dan ekspor Excel.
class BackupController extends GetxController {
  BackupController({
    required BackupService backup,
    required SharedPrefsService preferences,
    required TransactionRepository transactions,
    required CategoryRepository categories,
    required BudgetRepository budgets,
    DateTime Function()? clock,
  }) : _backup = backup,
       _preferences = preferences,
       _transactions = transactions,
       _categories = categories,
       _budgets = budgets,
       _clock = clock ?? DateTime.now;

  final BackupService _backup;
  final SharedPrefsService _preferences;
  final TransactionRepository _transactions;
  final CategoryRepository _categories;
  final BudgetRepository _budgets;
  final DateTime Function() _clock;

  final counts = <String, int>{}.obs;
  final lastBackupAt = Rxn<DateTime>();
  final period = ExportPeriod.thisMonth.obs;
  final busy = false.obs;

  int countOf(String table) => counts[table] ?? 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    try {
      counts.assignAll(await _backup.counts());
      lastBackupAt.value = await _preferences.getLastBackupAt();
    } catch (_) {
      // Kartu tetap tampil tanpa angka.
    }
  }

  /// Menulis berkas .tally lalu membuka lembar bagikan. Mengembalikan pesan
  /// galat, atau null bila berhasil.
  Future<String?> createBackup() => _run(() async {
    final now = _clock();
    final file = await _writeTemp(
      'Tally-cadangan-${_stamp(now)}.${BackupService.extension}',
      utf8.encode(await _backup.encode()),
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/octet-stream')],
        subject: 'Cadangan Tally'.tr,
      ),
    );
    await _preferences.setLastBackupAt(now);
    lastBackupAt.value = now;
  }, 'Gagal membuat cadangan.'.tr);

  /// Memilih berkas cadangan dan membacanya untuk pratinjau.
  /// Null bila pengguna batal memilih.
  Future<BackupPreview?> pickBackup() async {
    final file = await FilePicker.pickFile(dialogTitle: 'Pilih cadangan'.tr);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      throw BackupFormatException('Berkas ini bukan cadangan Tally.'.tr);
    }
    return _backup.decode(text);
  }

  /// Mengganti data di HP ini dengan isi cadangan.
  Future<String?> restore(BackupPreview preview) => _run(() async {
    await _backup.restore(preview);
    await load();
    if (Get.isRegistered<DataRefreshService>()) {
      Get.find<DataRefreshService>().bump();
    }
    if (Get.isRegistered<RecurringReminderService>()) {
      await Get.find<RecurringReminderService>().reschedule();
    }
    if (Get.isRegistered<HomeWidgetService>()) {
      await Get.find<HomeWidgetService>().update();
    }
  }, 'Gagal memulihkan cadangan.'.tr);

  /// Membuat .xlsx untuk [period] lalu membuka lembar bagikan.
  Future<String?> exportExcel() => _run(() async {
    final now = _clock();
    final selected = period.value;
    final range = await _rangeFor(selected, now);
    final transactions = await _transactions.getAll(range: range)
      ..sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
    final categories = {
      for (final category in await _categories.getAll(includeArchived: true))
        if (category.id != null) category.id!: category,
    };
    final budgets = <BudgetUsage>[];
    for (final budget in await _budgets.getAll()) {
      final budgetRange = DateRange(
        start: budget.startDate,
        end: budget.endDate,
      );
      var used = 0;
      for (final t in await _transactions.getAll(range: budgetRange)) {
        if (t.type != TransactionType.expense) continue;
        if (budget.categoryId != null && t.categoryId != budget.categoryId) {
          continue;
        }
        used += t.amount;
      }
      budgets.add(BudgetUsage(budget, used));
    }
    final bytes = const ExcelWorkbookBuilder().build(
      title: ExportNaming.title(selected, range),
      range: range,
      exportedAt: now,
      transactions: transactions,
      categories: categories,
      budgets: budgets,
    );
    final file = await _writeTemp(ExportNaming.fileName(selected, now), bytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        subject: 'Ekspor transaksi Tally'.tr,
      ),
    );
  }, 'Gagal mengekspor ke Excel.'.tr);

  Future<DateRange> _rangeFor(ExportPeriod value, DateTime now) async {
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return switch (value) {
      ExportPeriod.thisMonth => DateRange(
        start: DateTime(now.year, now.month),
        end: endOfMonth,
      ),
      ExportPeriod.threeMonths => DateRange(
        start: DateTime(now.year, now.month - 2),
        end: endOfMonth,
      ),
      ExportPeriod.all => DateRange(
        start: await _transactions.firstTransactionDate() ?? now,
        end: now,
      ),
    };
  }

  Future<String?> _run(Future<void> Function() action, String failure) async {
    if (busy.value) return null;
    busy.value = true;
    try {
      await action();
      return null;
    } catch (_) {
      return failure;
    } finally {
      busy.value = false;
    }
  }

  Future<File> _writeTemp(String name, List<int> bytes) async {
    final directory = await getTemporaryDirectory();
    final file = File(path.join(directory.path, name));
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  static String _stamp(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  /// Ringkasan isi: "128 transaksi · 6 anggaran · 15 kategori".
  static String summary(int Function(String table) count) =>
      '@tx transaksi · @budget anggaran · @cat kategori'.trParams({
        'tx': '${count(DatabaseTables.transactions)}',
        'budget': '${count(DatabaseTables.budgets)}',
        'cat': '${count(DatabaseTables.categories)}',
      });
}
