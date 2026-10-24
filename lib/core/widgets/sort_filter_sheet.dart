import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../services/app_haptics.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';
import '../utils/date_label.dart';
import '../utils/formatter.dart';
import 'app_button.dart';
import 'app_date_picker.dart';
import 'category_icon_box.dart';

/// Kategori yang bisa dipilih di lembar saring (data tampilan saja).
class FilterCategory {
  const FilterCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.color,
    this.isIncome = false,
  });

  final int id;
  final String name;
  final String iconKey;
  final Color color;

  /// Kategori pemasukan tampil di baris terpisah dari pengeluaran.
  final bool isIncome;
}

/// Pilihan urutan dan saringan dari [showSortFilterSheet].
class SortFilterValue<T> {
  const SortFilterValue({
    required this.sort,
    this.categoryIds = const {},
    this.minAmount,
    this.maxAmount,
    this.range,
  });

  final T sort;
  final Set<int> categoryIds;
  final int? minAmount;
  final int? maxAmount;
  final DateTimeRange? range;

  /// Jumlah saringan aktif (urutan tidak dihitung), untuk lencana chip.
  int get activeCount =>
      (categoryIds.isEmpty ? 0 : 1) +
      (minAmount != null || maxAmount != null ? 1 : 0) +
      (range == null ? 0 : 1);
}

/// Satu lembar untuk urutkan + saring: urutan, kategori (ikon), nominal, dan
/// tanggal (kalender rentang: tanggal sama dua kali = satu hari).
/// [countFor] menghitung jumlah hasil untuk tombol "Tampilkan N".
Future<SortFilterValue<T>?> showSortFilterSheet<T>(
  BuildContext context, {
  required SortFilterValue<T> value,
  required T defaultSort,
  required List<T> sortOptions,
  required String Function(T) sortLabel,
  List<FilterCategory> categories = const [],
  bool showAmount = true,
  bool showDate = true,
  Future<int?> Function(SortFilterValue<T> value)? countFor,
}) => showModalBottomSheet<SortFilterValue<T>>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => _SortFilterBody<T>(
    initial: value,
    defaultSort: defaultSort,
    sortOptions: sortOptions,
    sortLabel: sortLabel,
    categories: categories,
    showAmount: showAmount,
    showDate: showDate,
    countFor: countFor,
  ),
);

class _SortFilterBody<T> extends StatefulWidget {
  const _SortFilterBody({
    required this.initial,
    required this.defaultSort,
    required this.sortOptions,
    required this.sortLabel,
    required this.categories,
    required this.showAmount,
    required this.showDate,
    required this.countFor,
  });

  final SortFilterValue<T> initial;
  final T defaultSort;
  final List<T> sortOptions;
  final String Function(T) sortLabel;
  final List<FilterCategory> categories;
  final bool showAmount;
  final bool showDate;
  final Future<int?> Function(SortFilterValue<T> value)? countFor;

  @override
  State<_SortFilterBody<T>> createState() => _SortFilterBodyState<T>();
}

class _SortFilterBodyState<T> extends State<_SortFilterBody<T>> {
  late T _sort = widget.initial.sort;
  late final Set<int> _ids = {...widget.initial.categoryIds};
  late DateTimeRange? _range = widget.initial.range;
  late final _min = TextEditingController(
    text: widget.initial.minAmount == null
        ? ''
        : formatIdrPlain(widget.initial.minAmount!),
  );
  late final _max = TextEditingController(
    text: widget.initial.maxAmount == null
        ? ''
        : formatIdrPlain(widget.initial.maxAmount!),
  );
  int? _count;
  Timer? _debounce;

  SortFilterValue<T> get _value => SortFilterValue<T>(
    sort: _sort,
    categoryIds: {..._ids},
    minAmount: _amount(_min),
    maxAmount: _amount(_max),
    range: _range,
  );

  static int? _amount(TextEditingController c) {
    final digits = c.text.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? null : int.parse(digits);
  }

  @override
  void initState() {
    super.initState();
    _refreshCount();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  void _changed(VoidCallback change) {
    setState(change);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _refreshCount);
  }

  Future<void> _refreshCount() async {
    final count = widget.countFor;
    if (count == null) return;
    final result = await count(_value);
    if (mounted) setState(() => _count = result);
  }

  void _reset() => _changed(() {
    _sort = widget.defaultSort;
    _ids.clear();
    _range = null;
    _min.clear();
    _max.clear();
  });

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showAppDateRangePicker(
      context,
      initialRange: _range ?? DateTimeRange(start: today, end: today),
      firstDate: DateTime(2000),
      lastDate: today,
      title: 'Tanggal'.tr,
    );
    if (picked != null) _changed(() => _range = picked);
  }

  @override
  Widget build(BuildContext context) {
    final expense = [
      for (final c in widget.categories)
        if (!c.isIncome) c,
    ];
    final income = [
      for (final c in widget.categories)
        if (c.isIncome) c,
    ];
    final grouped = expense.isNotEmpty && income.isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Urutkan & saring'.tr,
                  style: AppText.display(size: 21),
                ),
              ),
              TextButton(
                onPressed: _reset,
                style: TextButton.styleFrom(foregroundColor: AppColors.spend),
                child: Text(
                  'Reset'.tr,
                  style: AppText.body(
                    size: 12.5,
                    weight: FontWeight.w700,
                    color: AppColors.spend,
                  ),
                ),
              ),
            ],
          ),
          _Label('URUTKAN'.tr),
          _Slider(
            spacing: 6,
            children: [
              for (final option in widget.sortOptions)
                _Pill(
                  label: widget.sortLabel(option),
                  selected: option == _sort,
                  onTap: () => _changed(() => _sort = option),
                ),
            ],
          ),
          if (widget.categories.isNotEmpty) ...[
            _Label('KATEGORI'.tr),
            for (final (title, group) in [
              ('Pengeluaran'.tr, expense),
              ('Pemasukan'.tr, income),
            ])
              if (group.isNotEmpty) ...[
                if (grouped)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      title,
                      style: AppText.body(
                        size: 11.5,
                        weight: FontWeight.w700,
                        color: AppColors.ink2,
                      ),
                    ),
                  ),
                _Slider(
                  spacing: 4,
                  children: [
                    for (final category in group)
                      _CategoryChoice(
                        category: category,
                        selected: _ids.contains(category.id),
                        onTap: () => _changed(() {
                          if (!_ids.remove(category.id)) {
                            _ids.add(category.id);
                          }
                        }),
                      ),
                  ],
                ),
                if (grouped && group == expense) const SizedBox(height: 10),
              ],
          ],
          if (widget.showAmount) ...[
            _Label('NOMINAL'.tr),
            Row(
              children: [
                Expanded(
                  child: _AmountField(
                    key: const Key('filter-min'),
                    controller: _min,
                    hint: 'Minimal'.tr,
                    onChanged: () => _changed(() {}),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('–', style: TextStyle(color: AppColors.mut)),
                ),
                Expanded(
                  child: _AmountField(
                    key: const Key('filter-max'),
                    controller: _max,
                    hint: 'Tanpa batas'.tr,
                    onChanged: () => _changed(() {}),
                  ),
                ),
              ],
            ),
          ],
          if (widget.showDate) ...[
            _Label('TANGGAL'.tr),
            Material(
              color: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.field),
                side: const BorderSide(color: AppColors.line),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.field),
                onTap: _pickRange,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _range == null
                              ? 'Semua tanggal'.tr
                              : _range!.start == _range!.end
                              ? DateLabel.day(_range!.start)
                              : '${DateLabel.day(_range!.start)} – ${DateLabel.day(_range!.end)}',
                          style: AppText.mono(
                            size: 12.5,
                            color: _range == null
                                ? AppColors.mut
                                : AppColors.ink,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                      if (_range != null) ...[
                        Text(
                          '@count hari'.trParams({
                            'count':
                                '${_range!.end.difference(_range!.start).inDays + 1}',
                          }),
                          style: AppText.body(size: 11, color: AppColors.mut),
                        ),
                        IconButton(
                          tooltip: 'Hapus tanggal'.tr,
                          onPressed: () => _changed(() => _range = null),
                          icon: const Icon(
                            LucideIcons.x,
                            size: 16,
                            color: AppColors.mut,
                          ),
                        ),
                      ] else
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            LucideIcons.calendar,
                            size: 16,
                            color: AppColors.ink2,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          AppButton(
            label: _count == null
                ? 'Terapkan'.tr
                : 'Tampilkan @count hasil'.trParams({'count': '$_count'}),
            onPressed: () => Navigator.of(context).pop(_value),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 8),
    child: Text(
      text,
      style: AppText.body(
        size: 10.5,
        weight: FontWeight.w700,
        color: AppColors.mut,
        letterSpacing: 0.8,
      ),
    ),
  );
}

/// Satu baris yang digeser ke samping; menembus padding lembar sampai tepi.
class _Slider extends StatelessWidget {
  const _Slider({required this.children, required this.spacing});

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    clipBehavior: Clip.none,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          children[i],
        ],
      ],
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: () {
        AppHaptics.select();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : AppColors.paper2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: AppText.body(
            size: 12,
            weight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.paper : AppColors.ink2,
          ),
        ),
      ),
    ),
  );
}

class _CategoryChoice extends StatelessWidget {
  const _CategoryChoice({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final FilterCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: category.name,
    child: Semantics(
      button: true,
      selected: selected,
      label: category.name,
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('filter-category-${category.id}'),
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          AppHaptics.select();
          onTap();
        },
        child: SizedBox(
          width: 68,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected ? AppColors.ink : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: CategoryIconBox.category(
                      iconKey: category.iconKey,
                      color: category.color,
                      size: 42,
                    ),
                  ),
                  if (selected)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        width: 17,
                        height: 17,
                        decoration: const BoxDecoration(
                          color: AppColors.ink,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.check,
                          size: 11,
                          color: AppColors.paper,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                category.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: AppText.body(
                  size: 10.5,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.ink : AppColors.ink2,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide(color: color),
    );
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, _Grouping()],
      onChanged: (_) => onChanged(),
      style: AppText.mono(size: 12.5, letterSpacing: 0),
      decoration: InputDecoration(
        hintText: hint,
        prefixText: 'Rp ',
        isDense: true,
        filled: true,
        fillColor: AppColors.card,
        hintStyle: AppText.body(size: 12, color: AppColors.mut),
        enabledBorder: border(AppColors.line),
        focusedBorder: border(AppColors.ink),
        border: border(AppColors.line),
      ),
    );
  }
}

class _Grouping extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return const TextEditingValue();
    final text = formatIdrPlain(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
