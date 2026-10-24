import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/category_style.dart';
import '../../../core/utils/date_label.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/category_icon_box.dart';
import '../../category/models/category_model.dart';
import '../../category/repositories/category_repository.dart';
import '../controllers/recurring_form_controller.dart';
import '../models/recurring_rule.dart';
import '../../../core/widgets/app_date_picker.dart';

/// Sheet tambah atau ubah recurring (§9.2). [edit] mengisi form dengan aturan
/// yang sudah ada. Simpan menutup sheet bila berhasil.
Future<bool> showRecurringAddSheet(
  BuildContext context, {
  CategoryRepository? categories,
  RecurringRule? edit,
}) async {
  final form = Get.find<RecurringFormController>();
  if (edit == null) {
    form.startNew();
  } else {
    form.startEdit(edit);
  }
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.card,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
      side: BorderSide(color: AppColors.line),
    ),
    builder: (_) => _RecurringAddBody(categories: categories),
  );
  return saved == true;
}

class _RecurringAddBody extends StatefulWidget {
  const _RecurringAddBody({this.categories});

  final CategoryRepository? categories;

  @override
  State<_RecurringAddBody> createState() => _RecurringAddBodyState();
}

class _RecurringAddBodyState extends State<_RecurringAddBody> {
  late final RecurringFormController _form =
      Get.find<RecurringFormController>();
  late final TextEditingController _name = TextEditingController(
    text: _form.name.value,
  );
  late final TextEditingController _amount = TextEditingController(
    text: _form.amountDigits.value,
  );
  List<CategoryModel> _all = const [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final repo =
        widget.categories ??
        (Get.isRegistered<CategoryRepository>()
            ? Get.find<CategoryRepository>()
            : null);
    if (repo == null) return;
    final all = await repo.getAll();
    if (!mounted) return;
    setState(() {
      _all = all;
    });
  }

  List<CategoryModel> get _options =>
      _all.where((c) => c.type == _transactionType(_form.type.value)).toList();

  TransactionType _transactionType(RecurringType type) =>
      type == RecurringType.income
      ? TransactionType.income
      : TransactionType.expense;

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context,
      initialDate: _form.startDate.value ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) _form.startDate.value = picked;
  }

  void _select(VoidCallback change) {
    change();
    setState(() {});
  }

  Future<void> _save() async {
    _form.name.value = _name.text;
    final ok = await _form.save();
    if (!mounted) return;
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _form.isEditing
                      ? 'Ubah transaksi berulang'.tr
                      : 'Transaksi berulang baru'.tr,
                  style: AppText.display(size: 19),
                ),
              ),
              IconButton(
                tooltip: 'Tutup'.tr,
                onPressed: () => Navigator.of(context).pop(false),
                icon: const Icon(LucideIcons.x, size: 18),
                color: AppColors.ink,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _Segment<RecurringType>(
            options: RecurringType.values,
            selected: _form.type.value,
            label: (t) =>
                t == RecurringType.income ? 'Pemasukan'.tr : 'Pengeluaran'.tr,
            color: (t) =>
                t == RecurringType.income ? AppColors.earn : AppColors.spend,
            onSelect: (t) => _select(() {
              _form.type.value = t;
              _form.categoryId.value = null;
            }),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _name,
            decoration: _fieldDecoration('Nama, contoh: Spotify'.tr),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('amount'),
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: _fieldDecoration('Jumlah (Rp), contoh: 55000'.tr),
            onChanged: (value) {
              _form.amountDigits.value = value.replaceAll(
                RegExp(r'[^0-9]'),
                '',
              );
            },
          ),
          _Label('Kategori'.tr),
          _CategoryRow(
            options: _options,
            selected: _form.categoryId.value,
            onSelect: (id) => _select(() => _form.categoryId.value = id),
          ),
          _Label('Berulang setiap'.tr),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final option in RecurringFrequency.values)
                AppChip(
                  label: _frequencyLabel(option),
                  selected: _form.frequency.value == option,
                  onTap: () => _select(() => _form.frequency.value = option),
                ),
              Obx(
                () => _DateChip(
                  date: _form.startDate.value ?? DateTime.now(),
                  onTap: _pickStartDate,
                ),
              ),
            ],
          ),
          _Label('Saat tanggalnya tiba'.tr),
          _Segment<RecurringMode>(
            options: RecurringMode.values,
            selected: _form.mode.value,
            label: (m) =>
                m == RecurringMode.ask ? 'Tanya dulu'.tr : 'Catat otomatis'.tr,
            color: (_) => AppColors.ink,
            onSelect: (m) => _select(() => _form.mode.value = m),
          ),
          Obx(() {
            final message = _form.error.value;
            if (message == null) return const SizedBox(height: 12);
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                message,
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w700,
                  color: AppColors.spend,
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Obx(
            () => AppButton(
              label: _form.isEditing
                  ? 'Simpan perubahan'.tr
                  : 'Simpan transaksi berulang'.tr,
              icon: Icons.check_rounded,
              loading: _form.saving.value,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: BorderSide(color: color),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: AppText.body(size: 13, color: AppColors.mut),
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: border(AppColors.line),
      focusedBorder: border(AppColors.ink),
      border: border(AppColors.line),
    );
  }

  String _frequencyLabel(RecurringFrequency f) => switch (f) {
    RecurringFrequency.weekly => 'Mingguan'.tr,
    RecurringFrequency.monthly => 'Bulanan'.tr,
    RecurringFrequency.yearly => 'Tahunan'.tr,
  };
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(text.toUpperCase(), style: AppText.label()),
    );
  }
}

/// Segmen dua/tiga pilihan, gaya sama dengan toggle di transaction form.
class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.options,
    required this.selected,
    required this.label,
    required this.color,
    required this.onSelect,
  });

  final List<T> options;
  final T selected;
  final String Function(T) label;
  final Color Function(T) color;
  final ValueChanged<T> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.paper2,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: option == selected,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: option == selected
                          ? color(option)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: Text(
                      label(option),
                      style: AppText.body(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: option == selected
                            ? Colors.white
                            : AppColors.mut,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.chip),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.calendar, size: 14, color: AppColors.ink),
              const SizedBox(width: 6),
              Text(
                'Mulai @date'.trParams({'date': DateLabel.day(date)}),
                style: AppText.body(
                  size: 12,
                  weight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  final List<CategoryModel> options;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Belum ada kategori untuk jenis ini.'.tr,
          style: AppText.body(size: 12, color: AppColors.mut),
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final category in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CategoryChoice(
                category: category,
                selected: category.id == selected,
                onTap: () => onSelect(category.id!),
              ),
            ),
        ],
      ),
    );
  }
}

class _CategoryChoice extends StatelessWidget {
  const _CategoryChoice({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final CategoryModel category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.smallButton),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 60,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.paper2 : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.smallButton),
            border: Border.all(
              color: selected ? AppColors.ink : Colors.transparent,
            ),
          ),
          child: Column(
            children: [
              CategoryIconBox(
                icon: CategoryStyle.icon(category.iconKey),
                color: CategoryStyle.color(category.colorValue),
              ),
              const SizedBox(height: 4),
              Text(
                category.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body(
                  size: 10,
                  weight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? AppColors.ink : AppColors.mut,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nominal ditampilkan dengan format IDR di label (dipakai di tampilan lain).
String recurringAmountLabel(int amount) => formatIdr(amount);
