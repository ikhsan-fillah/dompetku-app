import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/theme/app_colors.dart';
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
import '../controllers/transaction_form_controller.dart';
import '../models/transaction_model.dart';

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
  if (saved == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          editBudget != null
              ? 'Anggaran diperbarui.'
              : edit != null
              ? 'Perubahan transaksi tersimpan.'
              : requestedMode == FinancialInputMode.budget
              ? 'Anggaran tersimpan.'
              : requestedMode == FinancialInputMode.income
              ? 'Pemasukan tersimpan.'
              : 'Pengeluaran tersimpan.',
        ),
      ),
    );
  }
  if (saved == true && edit == null && editBudget == null) {
    _lastInputMode = requestedMode;
  }
  return saved == true;
}

String _paymentLabel(PaymentMethod method) => switch (method) {
  PaymentMethod.cash => 'Tunai',
  PaymentMethod.eWallet => 'E-wallet',
  PaymentMethod.qris => 'QRIS',
  PaymentMethod.bankTransfer => 'Transfer',
  PaymentMethod.debitCard => 'Kartu debit',
  PaymentMethod.creditCard => 'Kartu kredit',
  PaymentMethod.other => 'Lainnya',
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
    final picked = await showDatePicker(
      context: context,
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
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      budget.setDates(start: start ? picked : null, end: start ? null : picked);
    }
  }

  Future<void> _scanReceipt() async {
    final source = await showModalBottomSheet<ReceiptImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Scan struk', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Data hasil scan adalah usulan. Periksa kembali sebelum menyimpan.',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Ambil foto'),
                subtitle: const Text('Gunakan kamera untuk memotret struk'),
                onTap: () =>
                    Navigator.of(context).pop(ReceiptImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Pilih dari galeri'),
                subtitle: const Text('Pilih foto struk yang sudah ada'),
                onTap: () =>
                    Navigator.of(context).pop(ReceiptImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || source == null) return;
    final result = await _controller.scanReceipt(source);
    if (!mounted || result == null) return;
    _applyOcrResult(result);
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
              ? 'Data struk terisi. Periksa sebelum menyimpan.'
              : 'Sebagian data struk terisi. Lengkapi dan periksa kembali.',
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
    final textTheme = Theme.of(context).textTheme;
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
                        ? (_isEditing ? 'Edit anggaran' : 'Catat Keuangan')
                        : _isEditing
                        ? c.type.value == TransactionType.income
                              ? 'Edit pemasukan'
                              : 'Edit pengeluaran'
                        : 'Catat Keuangan',
                    style: textTheme.titleLarge,
                  ),
                ),
                if (!_isEditing)
                  Obx(
                    () => IconButton(
                      tooltip: 'Scan struk',
                      onPressed: c.scanning.value || c.saving.value
                          ? null
                          : _scanReceipt,
                      icon: c.scanning.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.document_scanner_outlined),
                    ),
                  ),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ModeToggle(mode: _mode, onChanged: _changeMode),
            const SizedBox(height: 16),
            Obx(() {
              final color = _isBudget
                  ? (_budgetController?.error.value == null
                        ? AppColors.teal
                        : AppColors.coral)
                  : c.type.value == TransactionType.expense
                  ? AppColors.coral
                  : AppColors.income;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
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
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                  decoration: InputDecoration(
                    labelText: _isBudget
                        ? 'Batas anggaran (IDR)'
                        : 'Jumlah (IDR)',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    floatingLabelAlignment: FloatingLabelAlignment.center,
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                    hintText: '0',
                    prefixText: 'Rp ',
                    prefixStyle: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            if (_isBudget && _budgetController != null) ...[
              Wrap(
                spacing: 8,
                children: [
                  AppChip(
                    label: 'Bulan ini',
                    selected: false,
                    onTap: () => _budgetController.setPreset(
                      BudgetPeriodPreset.currentMonth,
                    ),
                  ),
                  AppChip(
                    label: 'Bulan depan',
                    selected: false,
                    onTap: () => _budgetController.setPreset(
                      BudgetPeriodPreset.nextMonth,
                    ),
                  ),
                  AppChip(
                    label: '30 hari',
                    selected: false,
                    onTap: () => _budgetController.setPreset(
                      BudgetPeriodPreset.thirtyDays,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: _DateRow(
                        date: _budgetController.startDate.value,
                        label: 'Mulai',
                        onTap: () => _pickBudgetDate(true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DateRow(
                        date: _budgetController.endDate.value,
                        label: 'Selesai',
                        onTap: () => _pickBudgetDate(false),
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              Obx(() => _DateRow(date: c.date.value, onTap: _pickDate)),
            const _Label('Kategori'),
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
                title: const Text(
                  'Detail tambahan',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  _isBudget
                      ? 'Nama dan catatan anggaran'
                      : 'Metode pembayaran, nama, catatan',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                children: [
                  if (!_isBudget) ...[
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: _Label('Metode pembayaran'),
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
                        ? 'Nama anggaran (opsional)'
                        : 'Nama (opsional), contoh: Makan siang',
                    prefixIcon: Icons.edit_outlined,
                    textInputAction: TextInputAction.next,
                    onChanged: (value) => _isBudget
                        ? _budgetController?.name.value = value
                        : c.title.value = value,
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    controller: _noteField,
                    hint: 'Catatan (opsional)',
                    prefixIcon: Icons.notes_rounded,
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
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.coral,
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Obx(
              () => AppButton(
                label: _isBudget
                    ? (_isEditing ? 'Simpan perubahan' : 'Simpan anggaran')
                    : (_isEditing ? 'Simpan perubahan' : 'Simpan transaksi'),
                icon: Icons.check_rounded,
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
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: AppColors.muted,
        ),
      ),
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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _ToggleButton(
            label: 'Pengeluaran',
            selected: mode == FinancialInputMode.expense,
            color: AppColors.coral,
            onTap: () => onChanged(FinancialInputMode.expense),
          ),
          _ToggleButton(
            label: 'Pemasukan',
            selected: mode == FinancialInputMode.income,
            color: AppColors.income,
            onTap: () => onChanged(FinancialInputMode.income),
          ),
          _ToggleButton(
            label: 'Anggaran',
            selected: mode == FinancialInputMode.budget,
            color: AppColors.teal,
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
            padding: const EdgeInsets.symmetric(vertical: 13),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.date, required this.onTap, this.label});

  final DateTime date;
  final VoidCallback onTap;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateLabel = date == today
        ? 'Hari ini · ${DateLabel.day(date)}'
        : DateLabel.day(date);
    return Align(
      alignment: Alignment.center,
      child: Semantics(
        button: true,
        label: 'Pilih tanggal, ${label ?? dateLabel}',
        child: Material(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(99),
          child: InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 16,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label == null ? dateLabel : '$label · $dateLabel',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teal,
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
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'Belum ada kategori untuk jenis ini.',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
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
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.mintSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.tealLight : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              CategoryIconBox(
                icon: CategoryStyle.icon(category.iconKey),
                color: CategoryStyle.color(category.colorValue),
                size: 40,
              ),
              const SizedBox(height: 4),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? AppColors.ink : AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
