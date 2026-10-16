import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constant/domain_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_chip.dart';
import '../../category/models/category_model.dart';
import '../../category/repositories/category_repository.dart';
import '../controllers/recurring_form_controller.dart';
import '../models/recurring_rule.dart';

/// Sheet tambah recurring (§9.2). Simpan menutup sheet bila berhasil.
Future<bool> showRecurringAddSheet(
  BuildContext context, {
  CategoryRepository? categories,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AppColors.card,
    elevation: 0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
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
  late final RecurringFormController _form = Get.find<RecurringFormController>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _amount = TextEditingController();
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
    final repo = widget.categories ??
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

  List<CategoryModel> get _options => _all
      .where((c) => c.type == _transactionType(_form.type.value))
      .toList();

  TransactionType _transactionType(RecurringType type) =>
      type == RecurringType.income
      ? TransactionType.income
      : TransactionType.expense;

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
          Text('New recurring', style: AppText.display(size: 19)),
          const SizedBox(height: 14),
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('amount'),
            controller: _amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Amount (IDR)',
              prefixText: 'Rp ',
            ),
            onChanged: (value) {
              _form.amountDigits.value = value.replaceAll(RegExp(r'[^0-9]'), '');
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final option in RecurringType.values)
                Expanded(
                  child: AppChip(
                    label: option == RecurringType.income ? 'Income' : 'Expense',
                    selected: _form.type.value == option,
                    onTap: () => _select(() {
                      _form.type.value = option;
                      _form.categoryId.value = null;
                    }),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in _options)
                AppChip(
                  label: category.name,
                  selected: _form.categoryId.value == category.id,
                  onTap: () => _select(() => _form.categoryId.value = category.id),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              for (final option in RecurringFrequency.values)
                AppChip(
                  label: option.name,
                  selected: _form.frequency.value == option,
                  onTap: () => _select(() => _form.frequency.value = option),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              AppChip(
                label: 'Ask me first',
                selected: _form.mode.value == RecurringMode.ask,
                onTap: () => _select(() => _form.mode.value = RecurringMode.ask),
              ),
              AppChip(
                label: 'Record automatically',
                selected: _form.mode.value == RecurringMode.auto,
                onTap: () => _select(() => _form.mode.value = RecurringMode.auto),
              ),
            ],
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
              label: 'Save recurring',
              icon: Icons.check_rounded,
              loading: _form.saving.value,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }
}

/// Nominal ditampilkan dengan format IDR di label (dipakai di tampilan lain).
String recurringAmountLabel(int amount) => formatIdr(amount);
