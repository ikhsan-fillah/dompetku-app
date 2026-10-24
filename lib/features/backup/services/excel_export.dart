import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:get/get.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/utils/date_label.dart';
import '../../../core/utils/date_range.dart';
import '../../budget/models/budget_model.dart';
import '../../category/models/category_model.dart';
import '../../transaction/models/transaction_model.dart';

/// Rentang ekspor yang bisa dipilih di halaman Cadangan data.
enum ExportPeriod { thisMonth, threeMonths, all }

/// Anggaran beserta pemakaiannya untuk lembar "Anggaran".
class BudgetUsage {
  const BudgetUsage(this.budget, this.used);

  final BudgetModel budget;
  final int used;
}

/// Membangun berkas .xlsx yang rapi: judul dan periode di atas, baris kepala
/// tinta yang dibekukan, baris berselang, nominal sebagai angka berformat Rp,
/// dan tiga lembar (Transaksi, Per kategori, Anggaran). Tanpa I/O.
class ExcelWorkbookBuilder {
  const ExcelWorkbookBuilder();

  static const _ink = 'FF1C1B19';
  static const _paper = 'FFF7F5F0';
  static const _band = 'FFF1EEE7';
  static const _line = 'FFE4E0D6';
  static const _mut = 'FF8A857A';
  static const _earn = 'FF2F7D4F';
  static const _spend = 'FFC2412D';

  /// Baris kepala tabel (0-based); baris di atasnya judul dan periode.
  static const headerRow = 3;

  List<int> build({
    required String title,
    required DateRange range,
    required DateTime exportedAt,
    required List<TransactionModel> transactions,
    required Map<int, CategoryModel> categories,
    required List<BudgetUsage> budgets,
  }) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';
    final txName = 'Transaksi'.tr;
    final catName = 'Per kategori'.tr;
    final budgetName = 'Anggaran'.tr;
    excel.rename(defaultSheet, txName);
    final subtitle = '@range · diekspor @at'.trParams({
      'range': DateLabel.range(range),
      'at': '${DateLabel.day(exportedAt)} ${_time(exportedAt)}',
    });

    _transactionsSheet(
      excel[txName],
      title,
      subtitle,
      transactions,
      categories,
    );
    _categorySheet(excel[catName], title, subtitle, transactions, categories);
    _budgetSheet(excel[budgetName], title, subtitle, budgets, categories);
    excel.setDefaultSheet(txName);
    return freezeHeader(excel.encode()!);
  }

  // ---------- lembar ----------

  void _transactionsSheet(
    Sheet sheet,
    String title,
    String subtitle,
    List<TransactionModel> rows,
    Map<int, CategoryModel> categories,
  ) {
    _heading(sheet, title, subtitle, 6);
    _header(sheet, [
      'Tanggal'.tr,
      'Judul'.tr,
      'Kategori'.tr,
      'Jenis'.tr,
      'Pemasukan'.tr,
      'Pengeluaran'.tr,
    ], numericFrom: 4);
    var income = 0;
    var expense = 0;
    for (var i = 0; i < rows.length; i++) {
      final t = rows[i];
      final r = headerRow + 1 + i;
      final isIncome = t.type == TransactionType.income;
      if (isIncome) {
        income += t.amount;
      } else {
        expense += t.amount;
      }
      final date = t.transactionDate.toLocal();
      _cell(
        sheet,
        0,
        r,
        DateCellValue(year: date.year, month: date.month, day: date.day),
        i,
        format: NumFormat.custom(formatCode: 'd mmm yyyy'),
      );
      _cell(sheet, 1, r, TextCellValue(t.title), i);
      _cell(
        sheet,
        2,
        r,
        TextCellValue(categories[t.categoryId]?.displayName ?? '-'),
        i,
      );
      _cell(
        sheet,
        3,
        r,
        TextCellValue(isIncome ? 'Pemasukan'.tr : 'Pengeluaran'.tr),
        i,
      );
      _money(sheet, 4, r, isIncome ? t.amount : null, i, color: _earn);
      _money(sheet, 5, r, isIncome ? null : t.amount, i, color: _spend);
    }
    final total = headerRow + 1 + rows.length;
    _label(sheet, 3, total, 'Total'.tr);
    _moneyBold(sheet, 4, total, income, top: true);
    _moneyBold(sheet, 5, total, expense, top: true);
    _label(sheet, 3, total + 1, 'Saldo'.tr);
    _moneyBold(sheet, 5, total + 1, income - expense);
    _widths(sheet, const [14, 30, 20, 14, 18, 18]);
  }

  void _categorySheet(
    Sheet sheet,
    String title,
    String subtitle,
    List<TransactionModel> rows,
    Map<int, CategoryModel> categories,
  ) {
    _heading(sheet, title, subtitle, 5);
    _header(sheet, [
      'Kategori'.tr,
      'Jenis'.tr,
      'Transaksi'.tr,
      'Total'.tr,
      'Persen'.tr,
    ], numericFrom: 2);
    final totals = <(int, TransactionType), (int, int)>{};
    final byType = <TransactionType, int>{};
    for (final t in rows) {
      final key = (t.categoryId, t.type);
      final current = totals[key] ?? (0, 0);
      totals[key] = (current.$1 + 1, current.$2 + t.amount);
      byType[t.type] = (byType[t.type] ?? 0) + t.amount;
    }
    final entries = totals.entries.toList()
      ..sort((a, b) {
        final type = a.key.$2.index.compareTo(b.key.$2.index);
        return type != 0 ? type : b.value.$2.compareTo(a.value.$2);
      });
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final r = headerRow + 1 + i;
      final type = entry.key.$2;
      final isIncome = type == TransactionType.income;
      final sum = byType[type] ?? 0;
      _cell(
        sheet,
        0,
        r,
        TextCellValue(categories[entry.key.$1]?.displayName ?? '-'),
        i,
      );
      _cell(
        sheet,
        1,
        r,
        TextCellValue(isIncome ? 'Pemasukan'.tr : 'Pengeluaran'.tr),
        i,
      );
      _cell(
        sheet,
        2,
        r,
        IntCellValue(entry.value.$1),
        i,
        align: HorizontalAlign.Right,
      );
      _money(sheet, 3, r, entry.value.$2, i, color: isIncome ? _earn : _spend);
      _cell(
        sheet,
        4,
        r,
        DoubleCellValue(sum == 0 ? 0 : entry.value.$2 / sum),
        i,
        format: NumFormat.custom(formatCode: '0.0%'),
        align: HorizontalAlign.Right,
      );
    }
    _widths(sheet, const [24, 14, 12, 18, 10]);
  }

  void _budgetSheet(
    Sheet sheet,
    String title,
    String subtitle,
    List<BudgetUsage> budgets,
    Map<int, CategoryModel> categories,
  ) {
    _heading(sheet, title, subtitle, 7);
    _header(sheet, [
      'Anggaran'.tr,
      'Kategori'.tr,
      'Periode'.tr,
      'Batas'.tr,
      'Terpakai'.tr,
      'Sisa'.tr,
      'Persen'.tr,
    ], numericFrom: 3);
    for (var i = 0; i < budgets.length; i++) {
      final item = budgets[i];
      final b = item.budget;
      final r = headerRow + 1 + i;
      final remaining = b.amountLimit - item.used;
      _cell(sheet, 0, r, TextCellValue(b.name), i);
      _cell(
        sheet,
        1,
        r,
        TextCellValue(
          b.categoryId == null
              ? 'Semua kategori'.tr
              : categories[b.categoryId]?.displayName ?? '-',
        ),
        i,
      );
      _cell(
        sheet,
        2,
        r,
        TextCellValue(
          DateLabel.range(DateRange(start: b.startDate, end: b.endDate)),
        ),
        i,
      );
      _money(sheet, 3, r, b.amountLimit, i);
      _money(sheet, 4, r, item.used, i, color: _spend);
      _money(sheet, 5, r, remaining, i, color: remaining < 0 ? _spend : _earn);
      _cell(
        sheet,
        6,
        r,
        DoubleCellValue(b.amountLimit == 0 ? 0 : item.used / b.amountLimit),
        i,
        format: NumFormat.custom(formatCode: '0%'),
        align: HorizontalAlign.Right,
      );
    }
    _widths(sheet, const [24, 20, 24, 16, 16, 16, 10]);
  }

  // ---------- gaya ----------

  static final _rp = NumFormat.custom(formatCode: '"Rp" #,##0;-"Rp" #,##0');

  void _heading(Sheet sheet, String title, String subtitle, int columns) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
      ..value = TextCellValue(title)
      ..cellStyle = CellStyle(
        bold: true,
        fontSize: 15,
        fontColorHex: ExcelColor.fromHexString(_ink),
      );
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
      ..value = TextCellValue(subtitle)
      ..cellStyle = CellStyle(
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString(_mut),
      );
    sheet.setRowHeight(0, 24);
    for (final row in [0, 1]) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: columns - 1, rowIndex: row),
      );
    }
  }

  void _header(Sheet sheet, List<String> labels, {required int numericFrom}) {
    for (var c = 0; c < labels.length; c++) {
      sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: headerRow),
        )
        ..value = TextCellValue(labels[c])
        ..cellStyle = CellStyle(
          bold: true,
          fontColorHex: ExcelColor.fromHexString(_paper),
          backgroundColorHex: ExcelColor.fromHexString(_ink),
          horizontalAlign: c >= numericFrom
              ? HorizontalAlign.Right
              : HorizontalAlign.Left,
          verticalAlign: VerticalAlign.Center,
        );
    }
    sheet.setRowHeight(headerRow, 22);
  }

  void _cell(
    Sheet sheet,
    int column,
    int row,
    CellValue value,
    int index, {
    NumFormat format = NumFormat.standard_0,
    HorizontalAlign align = HorizontalAlign.Left,
    String color = _ink,
  }) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row))
      ..value = value
      ..cellStyle = CellStyle(
        fontColorHex: ExcelColor.fromHexString(color),
        backgroundColorHex: index.isOdd
            ? ExcelColor.fromHexString(_band)
            : ExcelColor.none,
        horizontalAlign: align,
        numberFormat: format,
        bottomBorder: Border(
          borderStyle: BorderStyle.Thin,
          borderColorHex: ExcelColor.fromHexString(_line),
        ),
      );
  }

  void _money(
    Sheet sheet,
    int column,
    int row,
    int? amount,
    int index, {
    String color = _ink,
  }) => _cell(
    sheet,
    column,
    row,
    amount == null ? TextCellValue('') : IntCellValue(amount),
    index,
    format: _rp,
    align: HorizontalAlign.Right,
    color: color,
  );

  void _label(Sheet sheet, int column, int row, String text) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row))
      ..value = TextCellValue(text)
      ..cellStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString(_ink),
        horizontalAlign: HorizontalAlign.Right,
      );
  }

  void _moneyBold(
    Sheet sheet,
    int column,
    int row,
    int amount, {
    bool top = false,
  }) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row))
      ..value = IntCellValue(amount)
      ..cellStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString(_ink),
        horizontalAlign: HorizontalAlign.Right,
        numberFormat: _rp,
        topBorder: top
            ? Border(
                borderStyle: BorderStyle.Medium,
                borderColorHex: ExcelColor.fromHexString(_ink),
              )
            : null,
      );
  }

  void _widths(Sheet sheet, List<double> widths) {
    for (var c = 0; c < widths.length; c++) {
      sheet.setColumnWidth(c, widths[c]);
    }
  }

  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}.'
      '${value.minute.toString().padLeft(2, '0')}';

  /// Membekukan baris judul sampai kepala tabel di setiap lembar. Paket excel
  /// belum mendukung panel beku, jadi XML lembar disunting langsung.
  static List<int> freezeHeader(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final out = Archive();
    const pane =
        '<pane ySplit="${headerRow + 1}" topLeftCell="A${headerRow + 2}" '
        'activePane="bottomLeft" state="frozen"/>';
    final sheetView = RegExp(r'<sheetView\b([^>]*?)(/>|>)');
    for (final file in archive.files) {
      if (!file.isFile ||
          !file.name.startsWith('xl/worksheets/') ||
          !file.name.endsWith('.xml')) {
        out.addFile(file);
        continue;
      }
      final xml = utf8.decode(file.content as List<int>);
      final updated = xml.replaceFirstMapped(sheetView, (m) {
        final attrs = m.group(1)!;
        return m.group(2) == '/>'
            ? '<sheetView$attrs>$pane</sheetView>'
            : '<sheetView$attrs>$pane';
      });
      final data = utf8.encode(updated);
      out.addFile(ArchiveFile(file.name, data.length, data));
    }
    return ZipEncoder().encode(out)!;
  }
}

/// Judul workbook dan nama berkas untuk periode ekspor.
abstract final class ExportNaming {
  static String title(ExportPeriod period, DateRange range) => switch (period) {
    ExportPeriod.thisMonth => 'Tally · Transaksi @month'.trParams({
      'month': '${AppLanguage.monthLong(range.end.month)} ${range.end.year}',
    }),
    ExportPeriod.threeMonths => 'Tally · Transaksi @range'.trParams({
      'range': DateLabel.range(range),
    }),
    ExportPeriod.all => 'Tally · Semua transaksi'.tr,
  };

  static String fileName(ExportPeriod period, DateTime now) {
    final month = AppLanguage.monthShort(now.month);
    return switch (period) {
      ExportPeriod.thisMonth => 'Tally-Transaksi-$month-${now.year}.xlsx',
      ExportPeriod.threeMonths =>
        'Tally-Transaksi-3-bulan-$month-${now.year}.xlsx',
      ExportPeriod.all => 'Tally-Transaksi-semua-${now.year}.xlsx',
    };
  }
}
