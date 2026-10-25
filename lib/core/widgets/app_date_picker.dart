import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../i18n/app_language.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../utils/date_label.dart';
import 'app_button.dart';

/// Pemilih tanggal aplikasi, pengganti `showDatePicker` bawaan:
/// - [showAppDatePicker]: satu tanggal (transaksi, anggaran, struk, dll).
/// - [showAppDateRangePicker]: rentang "Dari" dan "Sampai" (periode kustom).
/// Keduanya bisa lompat bulan dengan mengetuk judul bulan.

DateTime _dayOf(DateTime value) => DateTime(value.year, value.month, value.day);

DateTime _monthOf(DateTime value) => DateTime(value.year, value.month);

DateTime _clampDay(DateTime value, DateTime first, DateTime last) {
  final day = _dayOf(value);
  if (day.isBefore(first)) return first;
  if (day.isAfter(last)) return last;
  return day;
}

Future<T?> _showSheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      // Latar, garis, dan sudut mengikuti tema lembar (sama dengan Catat
      // Keuangan).
      builder: (_) => child,
    );

/// Memilih satu tanggal di antara [firstDate] dan [lastDate] (inklusif).
Future<DateTime?> showAppDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? title,
}) {
  final first = _dayOf(firstDate);
  final last = _dayOf(lastDate);
  return _showSheet<DateTime>(
    context,
    AppSingleDateSheet(
      initialDate: _clampDay(initialDate, first, last),
      firstDate: first,
      lastDate: last,
      title: title,
    ),
  );
}

/// Memilih rentang tanggal. [editEnd] membuka dengan kolom "Sampai" aktif.
Future<DateTimeRange?> showAppDateRangePicker(
  BuildContext context, {
  required DateTimeRange initialRange,
  required DateTime firstDate,
  required DateTime lastDate,
  bool editEnd = false,
  String? title,
}) {
  final first = _dayOf(firstDate);
  final last = _dayOf(lastDate);
  final start = _clampDay(initialRange.start, first, last);
  var end = _clampDay(initialRange.end, first, last);
  if (end.isBefore(start)) end = start;
  return _showSheet<DateTimeRange>(
    context,
    AppDateRangeSheet(
      initialStart: start,
      initialEnd: end,
      firstDate: first,
      lastDate: last,
      editEnd: editEnd,
      title: title,
    ),
  );
}

/// A · Lembar kalender satu tanggal.
class AppSingleDateSheet extends StatefulWidget {
  const AppSingleDateSheet({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.title,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String? title;

  @override
  State<AppSingleDateSheet> createState() => _AppSingleDateSheetState();
}

class _AppSingleDateSheetState extends State<AppSingleDateSheet> {
  late DateTime _selected = widget.initialDate;
  late DateTime _month = _monthOf(widget.initialDate);
  bool _pickingMonth = false;

  @override
  Widget build(BuildContext context) {
    return _SheetFrame(
      title: widget.title ?? 'Pilih tanggal'.tr,
      trailing: DateLabel.day(_selected),
      confirmLabel: 'Pilih'.tr,
      onConfirm: () => Navigator.of(context).pop(_selected),
      child: _Calendar(
        month: _month,
        pickingMonth: _pickingMonth,
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
        onMonthChanged: (month) => setState(() => _month = month),
        onToggleMonthPicker: () =>
            setState(() => _pickingMonth = !_pickingMonth),
        onMonthPicked: (month) => setState(() {
          _month = month;
          _pickingMonth = false;
        }),
        dayStyle: (day) =>
            day == _selected ? _DayLook.selected : _DayLook.normal,
        onDayTap: (day) => setState(() => _selected = day),
      ),
    );
  }
}

/// B · Rentang "Dari" dan "Sampai" dalam satu kalender.
class AppDateRangeSheet extends StatefulWidget {
  const AppDateRangeSheet({
    super.key,
    required this.initialStart,
    required this.initialEnd,
    required this.firstDate,
    required this.lastDate,
    this.editEnd = false,
    this.title,
  });

  final DateTime initialStart;
  final DateTime initialEnd;
  final DateTime firstDate;
  final DateTime lastDate;
  final bool editEnd;
  final String? title;

  @override
  State<AppDateRangeSheet> createState() => _AppDateRangeSheetState();
}

class _AppDateRangeSheetState extends State<AppDateRangeSheet> {
  late DateTime _start = widget.initialStart;
  late DateTime _end = widget.initialEnd;
  late bool _editingEnd = widget.editEnd;
  late DateTime _month = _monthOf(
    widget.editEnd ? widget.initialEnd : widget.initialStart,
  );
  bool _pickingMonth = false;

  /// Mengetuk "Dari" mengisi awal lalu pindah ke "Sampai". Di "Sampai",
  /// tanggal sebelum awal menjadi awal yang baru.
  void _tap(DateTime day) => setState(() {
    if (!_editingEnd) {
      _start = day;
      if (_end.isBefore(day)) _end = day;
      _editingEnd = true;
    } else if (day.isBefore(_start)) {
      _start = day;
    } else {
      _end = day;
    }
  });

  _DayLook _look(DateTime day) {
    if (day == _start || day == _end) return _DayLook.selected;
    if (day.isAfter(_start) && day.isBefore(_end)) return _DayLook.inRange;
    return _DayLook.normal;
  }

  @override
  Widget build(BuildContext context) {
    final days = _end.difference(_start).inDays + 1;
    return _SheetFrame(
      title: widget.title ?? 'Periode kustom'.tr,
      confirmLabel: 'Terapkan'.tr,
      onConfirm: () =>
          Navigator.of(context).pop(DateTimeRange(start: _start, end: _end)),
      header: Row(
        children: [
          Expanded(
            child: _RangeField(
              label: 'DARI'.tr,
              value: DateLabel.day(_start),
              active: !_editingEnd,
              onTap: () => setState(() {
                _editingEnd = false;
                _month = _monthOf(_start);
                _pickingMonth = false;
              }),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _RangeField(
              label: 'SAMPAI'.tr,
              value: DateLabel.day(_end),
              active: _editingEnd,
              onTap: () => setState(() {
                _editingEnd = true;
                _month = _monthOf(_end);
                _pickingMonth = false;
              }),
            ),
          ),
        ],
      ),
      footer: Text(
        '@count hari dipilih'.trParams({'count': '$days'}),
        textAlign: TextAlign.center,
        style: AppText.mono(
          size: 11.5,
          weight: FontWeight.w400,
          color: AppColors.ink2,
          letterSpacing: 0,
        ),
      ),
      child: _Calendar(
        month: _month,
        pickingMonth: _pickingMonth,
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
        onMonthChanged: (month) => setState(() => _month = month),
        onToggleMonthPicker: () =>
            setState(() => _pickingMonth = !_pickingMonth),
        onMonthPicked: (month) => setState(() {
          _month = month;
          _pickingMonth = false;
        }),
        dayStyle: _look,
        onDayTap: _tap,
      ),
    );
  }
}

/// Kerangka lembar: judul, isi, dan tombol Batal / aksi.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({
    required this.title,
    required this.child,
    required this.confirmLabel,
    required this.onConfirm,
    this.trailing,
    this.header,
    this.footer,
  });

  final String title;
  final String? trailing;
  final Widget? header;
  final Widget child;
  final Widget? footer;
  final String confirmLabel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(child: Text(title, style: AppText.display(size: 22))),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: AppText.mono(
                      size: 12,
                      weight: FontWeight.w400,
                      color: AppColors.ink2,
                      letterSpacing: 0,
                    ),
                  ),
              ],
            ),
            if (header != null) ...[const SizedBox(height: 14), header!],
            const SizedBox(height: 16),
            child,
            if (footer != null) ...[const SizedBox(height: 10), footer!],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    kind: AppButtonKind.outline,
                    label: 'Batal'.tr,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(label: confirmLabel, onPressed: onConfirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RangeField extends StatelessWidget {
  const _RangeField({
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.field),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.field),
            border: Border.all(
              color: active ? AppColors.ink : AppColors.line,
              width: active ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppText.body(
                  size: 10.5,
                  weight: FontWeight.w700,
                  color: AppColors.mut,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: AppText.mono(size: 13.5, letterSpacing: 0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _DayLook { normal, selected, inRange }

/// Navigasi bulan + grid hari, atau grid bulan (C) saat judul diketuk.
class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.month,
    required this.pickingMonth,
    required this.firstDate,
    required this.lastDate,
    required this.onMonthChanged,
    required this.onToggleMonthPicker,
    required this.onMonthPicked,
    required this.dayStyle,
    required this.onDayTap,
  });

  final DateTime month;
  final bool pickingMonth;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onMonthChanged;
  final VoidCallback onToggleMonthPicker;
  final ValueChanged<DateTime> onMonthPicked;
  final _DayLook Function(DateTime day) dayStyle;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final firstMonth = _monthOf(firstDate);
    final lastMonth = _monthOf(lastDate);
    final canPrevious = pickingMonth
        ? month.year > firstMonth.year
        : month.isAfter(firstMonth);
    final canNext = pickingMonth
        ? month.year < lastMonth.year
        : month.isBefore(lastMonth);
    final step = pickingMonth ? 12 : 1;
    DateTime shift(int delta) {
      final moved = DateTime(month.year, month.month + delta);
      if (moved.isBefore(firstMonth)) return firstMonth;
      if (moved.isAfter(lastMonth)) return lastMonth;
      return moved;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.smallButton),
                  onTap: onToggleMonthPicker,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pickingMonth
                              ? '${month.year}'
                              : '${AppLanguage.monthLong(month.month)} '
                                    '${month.year}',
                          style: AppText.body(
                            size: 15,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          pickingMonth
                              ? LucideIcons.chevronUp
                              : LucideIcons.chevronDown,
                          size: 14,
                          color: AppColors.ink,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            _NavButton(
              icon: LucideIcons.chevronLeft,
              tooltip: pickingMonth
                  ? 'Tahun sebelumnya'.tr
                  : 'Bulan sebelumnya'.tr,
              onTap: canPrevious ? () => onMonthChanged(shift(-step)) : null,
            ),
            const SizedBox(width: 6),
            _NavButton(
              icon: LucideIcons.chevronRight,
              tooltip: pickingMonth
                  ? 'Tahun berikutnya'.tr
                  : 'Bulan berikutnya'.tr,
              onTap: canNext ? () => onMonthChanged(shift(step)) : null,
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (pickingMonth)
          _MonthGrid(
            year: month.year,
            selectedMonth: month,
            firstMonth: firstMonth,
            lastMonth: lastMonth,
            onTap: onMonthPicked,
          )
        else
          _DayGrid(
            month: month,
            firstDate: firstDate,
            lastDate: lastDate,
            look: dayStyle,
            onTap: onDayTap,
          ),
      ],
    );
  }
}

/// Tombol panah: gaya sama dengan panah bulan di kartu tren.
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.smallButton),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.smallButton),
            border: Border.all(
              color: enabled ? AppColors.line : AppColors.line2,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: enabled ? AppColors.ink : const Color(0xFFC9C1AE),
          ),
        ),
      ),
    );
  }
}

const _weekdays = ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN'];

class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.month,
    required this.firstDate,
    required this.lastDate,
    required this.look,
    required this.onTap,
  });

  final DateTime month;
  final DateTime firstDate;
  final DateTime lastDate;
  final _DayLook Function(DateTime day) look;
  final ValueChanged<DateTime> onTap;

  static const _rowHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    final offset = DateTime(month.year, month.month).weekday - 1;
    final days = DateTime(month.year, month.month + 1, 0).day;
    final cells = offset + days;
    final rows = (cells / 7).ceil();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Column(
      children: [
        Row(
          children: [
            for (final name in _weekdays)
              Expanded(
                child: Text(
                  name.tr,
                  textAlign: TextAlign.center,
                  style: AppText.mono(
                    size: 10.5,
                    weight: FontWeight.w400,
                    color: AppColors.mut,
                    letterSpacing: 0,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (var row = 0; row < rows; row++)
          SizedBox(
            height: _rowHeight,
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: _cell(row * 7 + col - offset + 1, days, col, today),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(int dayNumber, int days, int col, DateTime today) {
    if (dayNumber < 1 || dayNumber > days) return const SizedBox.shrink();
    final day = DateTime(month.year, month.month, dayNumber);
    final enabled = !day.isBefore(firstDate) && !day.isAfter(lastDate);
    final state = look(day);
    final isToday = day == today;
    final selected = state == _DayLook.selected;

    // Pita rentang: membulat di tepi pekan.
    BoxDecoration? band;
    if (state == _DayLook.inRange) {
      band = BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(col == 0 ? 12 : 0),
          right: Radius.circular(col == 6 ? 12 : 0),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: band,
      alignment: Alignment.center,
      child: Semantics(
        button: enabled,
        selected: selected,
        label: DateLabel.day(day),
        excludeSemantics: true,
        child: InkWell(
          key: ValueKey('date-${day.year}-${day.month}-${day.day}'),
          onTap: enabled
              ? () {
                  onTap(day);
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.ink : null,
              borderRadius: BorderRadius.circular(12),
              border: isToday && !selected
                  ? Border.all(color: AppColors.ink, width: 1.5)
                  : null,
            ),
            child: Text(
              '$dayNumber',
              style: AppText.body(
                size: 14,
                weight: selected || isToday ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.paper
                    : enabled
                    ? AppColors.ink
                    : const Color(0xFFC9C1AE),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// C · Grid 12 bulan untuk tahun [year].
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.year,
    required this.selectedMonth,
    required this.firstMonth,
    required this.lastMonth,
    required this.onTap,
  });

  final int year;
  final DateTime selectedMonth;
  final DateTime firstMonth;
  final DateTime lastMonth;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var row = 0; row < 4; row++)
          Padding(
            padding: EdgeInsets.only(top: row == 0 ? 0 : 8),
            child: Row(
              children: [
                for (var col = 0; col < 3; col++) ...[
                  if (col > 0) const SizedBox(width: 8),
                  Expanded(child: _month(row * 3 + col + 1)),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _month(int number) {
    final month = DateTime(year, number);
    final enabled = !month.isBefore(firstMonth) && !month.isAfter(lastMonth);
    final selected = month == selectedMonth;
    return Semantics(
      button: enabled,
      selected: selected,
      label: '${AppLanguage.monthLong(number)} $year',
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('month-$year-$number'),
        onTap: enabled
            ? () {
                onTap(month);
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.paper,
            borderRadius: BorderRadius.circular(12),
            border: selected || !enabled
                ? null
                : Border.all(color: AppColors.line2),
          ),
          child: Text(
            AppLanguage.monthShort(number),
            style: AppText.body(
              size: 14,
              weight: selected ? FontWeight.w700 : FontWeight.w600,
              color: selected
                  ? AppColors.paper
                  : enabled
                  ? AppColors.ink
                  : const Color(0xFFC9C1AE),
            ),
          ),
        ),
      ),
    );
  }
}
