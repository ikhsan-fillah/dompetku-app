import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/category_style.dart';
import '../../../core/utils/date_label.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/category_icon_box.dart';
import '../../category/models/category_model.dart';
import '../../budget/controllers/budget_form_controller.dart';
import '../../budget/models/budget_model.dart';
import '../../receipt/services/receipt_image_picker.dart';
import '../../receipt/services/receipt_ocr_service.dart';
import '../../receipt/views/receipt_review_page.dart';
import '../controllers/transaction_form_controller.dart';
import '../models/transaction_model.dart';
import '../../../core/widgets/app_date_picker.dart';

/// Membuka sheet tambah/edit transaksi. Mengembalikan true bila tersimpan.
enum FinancialInputMode { expense, income, budget }

FinancialInputMode _lastInputMode = FinancialInputMode.expense;

Future<bool> showTransactionSheet(
  BuildContext context, {
  TransactionModel? edit,
  BudgetModel? editBudget,
  FinancialInputMode? initialMode,
}) async {
  final requestedMode = initialMode ?? _lastInputMode;
  final controller = Get.find<TransactionFormController>();
  final budgetController = Get.isRegistered<BudgetFormController>()
      ? Get.find<BudgetFormController>()
      : null;
  if (editBudget != null) {
    if (budgetController == null) return false;
    await budgetController.startEdit(editBudget);
  } else if (edit != null) {
    await controller.startEdit(edit);
  } else {
    if (requestedMode == FinancialInputMode.budget) {
      if (budgetController == null) return false;
      await budgetController.startNew();
    } else {
      await controller.startNew(
        initialType: requestedMode == FinancialInputMode.income
            ? TransactionType.income
            : TransactionType.expense,
      );
    }
  }
  if (!context.mounted) return false;
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
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: TransactionFormSheet(
        initialMode: editBudget != null
            ? FinancialInputMode.budget
            : edit != null
            ? edit.type == TransactionType.income
                  ? FinancialInputMode.income
                  : FinancialInputMode.expense
            : requestedMode,
        editingTransaction: edit,
        editingBudget: editBudget,
      ),
    ),
  );
  if (saved == true && edit == null && editBudget == null) {
    _lastInputMode = requestedMode;
  }
  return saved == true;
}

String _paymentLabel(PaymentMethod method) => switch (method) {
  PaymentMethod.cash => 'Tunai'.tr,
  PaymentMethod.eWallet => 'E-wallet'.tr,
  PaymentMethod.qris => 'QRIS'.tr,
  PaymentMethod.bankTransfer => 'Transfer'.tr,
  PaymentMethod.debitCard => 'Kartu debit'.tr,
  PaymentMethod.creditCard => 'Kartu kredit'.tr,
  PaymentMethod.other => 'Lainnya'.tr,
};

String _groupDigits(String digits) {
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Memformat input angka dengan pemisah ribuan (1.250.000).
class _ThousandsFormatter extends TextInputFormatter {
  const _ThousandsFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.length > 12) digits = digits.substring(0, 12);
    final text = _groupDigits(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class TransactionFormSheet extends StatefulWidget {
  const TransactionFormSheet({
    super.key,
    required this.initialMode,
    this.editingTransaction,
    this.editingBudget,
  });

  final FinancialInputMode initialMode;
  final TransactionModel? editingTransaction;
  final BudgetModel? editingBudget;

  @override
  State<TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<TransactionFormSheet> {
  late final TransactionFormController _controller =
      Get.find<TransactionFormController>();
  late final TextEditingController _amountField;
  late final TextEditingController _titleField;
  late final TextEditingController _noteField;
  late FinancialInputMode _mode;
  late final BudgetFormController? _budgetController =
      Get.isRegistered<BudgetFormController>()
      ? Get.find<BudgetFormController>()
      : null;

  bool get _isEditing =>
      widget.editingTransaction != null || widget.editingBudget != null;
  bool get _isBudget => _mode == FinancialInputMode.budget;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    final amountDigits = _isBudget
        ? _budgetController?.amountDigits.value ?? ''
        : _controller.amountDigits.value;
    final title = _isBudget
        ? _budgetController?.name.value ?? ''
        : _controller.title.value;
    final note = _isBudget
        ? _budgetController?.note.value ?? ''
        : _controller.note.value;
    _amountField = TextEditingController(text: _groupDigits(amountDigits));
    _titleField = TextEditingController(text: title);
    _noteField = TextEditingController(text: note);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await _controller.recoverLostReceipt();
      if (!mounted || result == null) return;
      _applyOcrResult(result);
    });
  }

  @override
  void dispose() {
    _amountField.dispose();
    _titleField.dispose();
    _noteField.dispose();
    super.dispose();
  }

  void _changeMode(FinancialInputMode mode) {
    if (_isEditing || mode == _mode) return;
    final budget = _budgetController;
    final amount = _isBudget
        ? budget?.amountDigits.value ?? ''
        : _controller.amountDigits.value;
    final title = _isBudget
        ? budget?.name.value ?? ''
        : _controller.title.value;
    final note = _isBudget ? budget?.note.value ?? '' : _controller.note.value;
    if (mode == FinancialInputMode.budget) {
      if (budget == null) return;
      budget.amountDigits.value = amount;
      budget.name.value = title;
      budget.note.value = note;
      if (budget.categoryId.value == null &&
          budget.availableCategories.isNotEmpty) {
        budget.categoryId.value = budget.availableCategories.first.id;
      }
      budget.error.value = null;
    } else {
      _controller.amountDigits.value = amount;
      _controller.title.value = title;
      _controller.note.value = note;
      _controller.setType(
        mode == FinancialInputMode.income
            ? TransactionType.income
            : TransactionType.expense,
      );
    }
    setState(() {
      _mode = mode;
      _amountField.text = _groupDigits(amount);
      _titleField.text = title;
      _noteField.text = note;
    });
  }

  Future<void> _pickDate() async {
    if (_isBudget) return;
    final picked = await showAppDatePicker(
      context,
      initialDate: _controller.date.value,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) _controller.setDate(picked);
  }

  Future<void> _pickBudgetDate(bool start) async {
    final budget = _budgetController;
    if (budget == null) return;
    final current = start ? budget.startDate.value : budget.endDate.value;
    final picked = await showAppDatePicker(
      context,
      initialDate: current,
      // Tanggal selesai tidak boleh sebelum tanggal mulai.
      firstDate: start ? DateTime(2000) : budget.startDate.value,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      budget.setDates(start: start ? picked : null, end: start ? null : picked);
    }
  }

  Future<void> _scanReceipt(ReceiptImageSource source) async {
    final result = await _controller.scanReceipt(source);
    if (!mounted || result == null) return;
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ReceiptReviewPage(
          scanResult: result,
          initialMerchant: result.receipt?.merchant,
          initialDate: result.receipt?.date,
          initialTotal: result.receipt?.total,
          onRetake: () => _scanReceipt(ReceiptImageSource.camera),
        ),
      ),
    );
    if (saved == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  void _applyOcrResult(ReceiptScanResult result) {
    if (!result.isSuccess) return;
    _amountField.text = _groupDigits(_controller.amountDigits.value);
    _titleField.value = TextEditingValue(
      text: _controller.title.value,
      selection: TextSelection.collapsed(
        offset: _controller.title.value.length,
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.receipt!.isComplete
              ? 'Data struk terisi. Periksa sebelum menyimpan.'.tr
              : 'Sebagian data struk terisi. Lengkapi dan periksa kembali.'.tr,
        ),
      ),
    );
  }

  Future<void> _save() async {
    final ok = _isBudget
        ? await _budgetController?.save() ?? false
        : await _controller.save();
    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.94,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isBudget
                        ? (_isEditing
                              ? 'Edit anggaran'.tr
                              : 'Catat Keuangan'.tr)
                        : _isEditing
                        ? c.type.value == TransactionType.income
                              ? 'Edit pemasukan'.tr
                              : 'Edit pengeluaran'.tr
                        : 'Catat Keuangan'.tr,
                    style: AppText.display(size: 19),
                  ),
                ),
                if (!_isEditing && !_isBudget)
                  Obx(
                    () => IconButton(
                      tooltip: 'Dari galeri'.tr,
                      onPressed: c.scanning.value || c.saving.value
                          ? null
                          : () => _scanReceipt(ReceiptImageSource.gallery),
                      icon: const Icon(LucideIcons.image, size: 18),
                      color: AppColors.ink,
                    ),
                  ),
                if (!_isEditing && !_isBudget)
                  Obx(
                    () => IconButton(
                      tooltip: 'Scan struk'.tr,
                      onPressed: c.scanning.value || c.saving.value
                          ? null
                          : () => _scanReceipt(ReceiptImageSource.camera),
                      icon: c.scanning.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.scanLine, size: 18),
                      color: AppColors.ink,
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
            _ModeToggle(mode: _mode, onChanged: _changeMode),
            const SizedBox(height: 16),
            Obx(() {
              final color = _isBudget
                  ? (_budgetController?.error.value == null
                        ? AppColors.ink
                        : AppColors.spend)
                  : c.type.value == TransactionType.expense
                  ? AppColors.spend
                  : AppColors.earn;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  controller: _amountField,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: const [_ThousandsFormatter()],
                  onChanged: (value) {
                    final digits = value.replaceAll('.', '');
                    if (_isBudget) {
                      _budgetController?.amountDigits.value = digits;
                      _budgetController?.error.value = null;
                    } else {
                      c.amountDigits.value = digits;
                      c.error.value = null;
                    }
                  },
                  style: AppText.display(size: 36, color: color),
                  decoration: InputDecoration(
                    labelText: _isBudget
                        ? 'Batas anggaran (IDR)'.tr
                        : 'Jumlah (IDR)'.tr,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    floatingLabelAlignment: FloatingLabelAlignment.center,
                    labelStyle: AppText.body(size: 11, color: AppColors.mut),
                    hintText: '0',
                    hintStyle: AppText.display(size: 36, color: AppColors.line),
                    prefixText: 'Rp ',
                    prefixStyle: AppText.display(size: 36, color: color),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            if (_isBudget && _budgetController != null) ...[
              Obx(
                () => _PeriodSegment(
                  selected: _budgetController.selectedPreset.value,
                  onSelect: _budgetController.setPreset,
                ),
              ),
              const SizedBox(height: 10),
              Obx(
                () => _BudgetDates(
                  start: _budgetController.startDate.value,
                  end: _budgetController.endDate.value,
                  onPickStart: () => _pickBudgetDate(true),
                  onPickEnd: () => _pickBudgetDate(false),
                ),
              ),
            ] else
              Obx(() => _DateRow(date: c.date.value, onTap: _pickDate)),
            _Label('Kategori'.tr),
            Obx(
              () => _CategoryRow(
                options: _isBudget
                    ? _budgetController?.availableCategories ?? const []
                    : c.availableCategories,
                selected: _isBudget
                    ? _budgetController?.categoryId.value
                    : c.categoryId.value,
                onSelect: (id) {
                  if (_isBudget) {
                    _budgetController?.setCategory(id);
                  } else {
                    c.categoryId.value = id;
                    c.error.value = null;
                  }
                },
              ),
            ),
            const SizedBox(height: 4),
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                initiallyExpanded: _isEditing,
                title: Text(
                  'Detail tambahan'.tr,
                  style: AppText.body(size: 13, weight: FontWeight.w700),
                ),
                subtitle: Text(
                  _isBudget
                      ? 'Nama dan catatan anggaran'.tr
                      : 'Metode pembayaran, nama, catatan'.tr,
                  style: AppText.body(size: 10.5, color: AppColors.mut),
                ),
                children: [
                  if (!_isBudget) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _Label('Metode pembayaran'.tr),
                    ),
                    Obx(
                      () => SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            for (final method in PaymentMethod.values)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: AppChip(
                                  label: _paymentLabel(method),
                                  selected: c.paymentMethod.value == method,
                                  onTap: () => c.paymentMethod.value = method,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _titleField,
                    hint: _isBudget
                        ? 'Nama anggaran (opsional)'.tr
                        : 'Nama (opsional), contoh: Makan siang'.tr,
                    prefixIcon: LucideIcons.pencil,
                    textInputAction: TextInputAction.next,
                    onChanged: (value) => _isBudget
                        ? _budgetController?.name.value = value
                        : c.title.value = value,
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    controller: _noteField,
                    hint: 'Catatan (opsional)'.tr,
                    prefixIcon: LucideIcons.fileText,
                    textInputAction: TextInputAction.done,
                    onChanged: (value) => _isBudget
                        ? _budgetController?.note.value = value
                        : c.note.value = value,
                  ),
                ],
              ),
            ),
            Obx(() {
              final message = _isBudget
                  ? _budgetController?.error.value
                  : c.error.value;
              if (message == null) return const SizedBox(height: 8);
              return Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 2),
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
            const SizedBox(height: 8),
            Obx(
              () => AppButton(
                label: _isBudget
                    ? (_isEditing
                          ? 'Simpan perubahan'.tr
                          : 'Simpan anggaran'.tr)
                    : (_isEditing
                          ? 'Simpan perubahan'.tr
                          : 'Simpan transaksi'.tr),
                icon: LucideIcons.check,
                loading: _isBudget
                    ? _budgetController?.saving.value ?? false
                    : c.saving.value,
                onPressed: _isBudget
                    ? _save
                    : c.scanning.value
                    ? null
                    : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(text.toUpperCase(), style: AppText.label()),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final FinancialInputMode mode;
  final ValueChanged<FinancialInputMode> onChanged;

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
          _ToggleButton(
            label: 'Pengeluaran'.tr,
            selected: mode == FinancialInputMode.expense,
            color: AppColors.spend,
            onTap: () => onChanged(FinancialInputMode.expense),
          ),
          _ToggleButton(
            label: 'Pemasukan'.tr,
            selected: mode == FinancialInputMode.income,
            color: AppColors.earn,
            onTap: () => onChanged(FinancialInputMode.income),
          ),
          _ToggleButton(
            label: 'Anggaran'.tr,
            selected: mode == FinancialInputMode.budget,
            color: AppColors.ink,
            onTap: () => onChanged(FinancialInputMode.budget),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              label,
              style: AppText.body(
                size: 12.5,
                weight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.mut,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pilihan periode anggaran: dua segmen sama lebar (bulan ini / bulan depan).
/// Tidak ada yang menyala bila tanggal diubah manual.
class _PeriodSegment extends StatelessWidget {
  const _PeriodSegment({required this.selected, required this.onSelect});

  final BudgetPeriodPreset? selected;
  final ValueChanged<BudgetPeriodPreset> onSelect;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: AppColors.paper2,
      borderRadius: BorderRadius.circular(AppRadius.field),
    ),
    child: Row(
      children: [
        _segment('Bulan ini'.tr, BudgetPeriodPreset.currentMonth),
        _segment('Bulan depan'.tr, BudgetPeriodPreset.nextMonth),
      ],
    ),
  );

  Widget _segment(String label, BudgetPeriodPreset preset) {
    final active = selected == preset;
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: label,
        child: Material(
          color: active ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.field - 3),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.field - 3),
            onTap: () => onSelect(preset),
            child: Container(
              height: 40,
              alignment: Alignment.center,
              decoration: active
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.field - 3),
                      border: Border.all(color: AppColors.line),
                    )
                  : null,
              child: Text(
                label,
                style: AppText.body(
                  size: 13,
                  weight: active ? FontWeight.w700 : FontWeight.w600,
                  color: active ? AppColors.ink : AppColors.ink2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tanggal mulai dan selesai dalam satu kartu, masing-masing bisa diketuk.
class _BudgetDates extends StatelessWidget {
  const _BudgetDates({
    required this.start,
    required this.end,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final DateTime start;
  final DateTime end;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.field),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      children: [
        Expanded(child: _cell('Mulai'.tr, start, onPickStart)),
        const Icon(LucideIcons.arrowRight, size: 16, color: AppColors.mut),
        Expanded(child: _cell('Selesai'.tr, end, onPickEnd)),
      ],
    ),
  );

  Widget _cell(String label, DateTime date, VoidCallback onTap) => Semantics(
    button: true,
    label: 'Pilih tanggal, @date'.trParams({
      'date': '$label ${DateLabel.day(date)}',
    }),
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadius.field),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppText.body(size: 10.5, color: AppColors.ink2)),
            const SizedBox(height: 2),
            Text(
              DateLabel.day(date),
              style: AppText.body(size: 13, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateLabel = date == today
        ? 'Hari ini · @date'.trParams({'date': DateLabel.day(date)})
        : DateLabel.day(date);
    return Align(
      alignment: Alignment.center,
      child: Semantics(
        button: true,
        label: 'Pilih tanggal, @date'.trParams({'date': dateLabel}),
        child: Material(
          color: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            side: const BorderSide(color: AppColors.line),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.chip),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.calendar,
                    size: 14,
                    color: AppColors.ink,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    dateLabel,
                    style: AppText.body(
                      size: 11.5,
                      weight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
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
        padding: EdgeInsets.symmetric(vertical: 8),
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
