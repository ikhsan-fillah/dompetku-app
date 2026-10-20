import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../../../core/widgets/app_button.dart';
import '../controllers/budget_form_controller.dart';
import '../models/budget_model.dart';

class BudgetFormPage extends StatefulWidget {
  const BudgetFormPage({super.key, this.budget});
  final BudgetModel? budget;

  @override
  State<BudgetFormPage> createState() => _BudgetFormPageState();
}

class _BudgetFormPageState extends State<BudgetFormPage> {
  final controller = Get.find<BudgetFormController>();
  late final TextEditingController _name;
  late final TextEditingController _amount;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _amount = TextEditingController();
    _prepare();
  }

  Future<void> _prepare() async {
    if (widget.budget == null) {
      await controller.startNew();
    } else {
      await controller.startEdit(widget.budget!);
    }
    if (!mounted) return;
    _name.text = controller.name.value;
    _amount.text = controller.amountDigits.value;
  }

  @override
  void dispose() {
    _name.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final current = start
        ? controller.startDate.value
        : controller.endDate.value;
    final selected = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      controller.setDates(
        start: start ? selected : null,
        end: start ? null : selected,
      );
    }
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  InputDecoration _decoration(String label, IconData icon) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.field),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      labelText: label,
      labelStyle: AppText.body(size: 13, color: AppColors.mut),
      floatingLabelStyle: AppText.body(
        size: 12,
        weight: FontWeight.w700,
        color: AppColors.ink,
      ),
      prefixIcon: Icon(icon, size: 18, color: AppColors.ink2),
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      border: border(AppColors.line),
      enabledBorder: border(AppColors.line),
      focusedBorder: border(AppColors.ink, 1.2),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Text(text, style: AppText.label()),
  );

  Widget _segment({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.card : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(
            color: active ? AppColors.line : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: active ? AppColors.ink : AppColors.mut),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppText.body(
                size: 12.5,
                weight: FontWeight.w700,
                color: active ? AppColors.ink : AppColors.mut,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _dateCard({
    required String label,
    required DateTime value,
    required bool start,
  }) => Expanded(
    child: Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.card),
        onTap: () => _pickDate(start),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.paper2,
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: const Icon(
                      LucideIcons.calendar,
                      size: 14,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(label, style: AppText.label()),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _date(value),
                style: AppText.mono(size: 13.5, weight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _errorPanel(String message) => Container(
    margin: const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.spendSoft,
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(LucideIcons.circleAlert, color: AppColors.spend, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: AppText.body(
              size: 12.5,
              weight: FontWeight.w700,
              color: AppColors.spend,
            ),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.paper,
    body: SafeArea(
      child: Column(
        children: [
          AppTitleBar(
            title: widget.budget == null ? 'Buat anggaran' : 'Edit anggaran',
          ),
          Expanded(
            child: Obx(() {
              final selected =
                  controller.availableCategories.any(
                    (c) => c.id == controller.categoryId.value,
                  )
                  ? controller.categoryId.value
                  : null;
              final overall = controller.isOverall;
              final startDate = controller.startDate.value;
              final endDate = controller.endDate.value;
              final error = controller.error.value;
              final saving = controller.saving.value;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  TextField(
                    controller: _name,
                    onChanged: (value) => controller.name.value = value,
                    style: AppText.body(size: 13.5),
                    decoration: _decoration(
                      'Nama anggaran',
                      LucideIcons.pencilLine,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amount,
                    onChanged: (value) => controller.amountDigits.value = value,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppText.mono(size: 13.5),
                    decoration: _decoration(
                      'Batas anggaran (Rp)',
                      LucideIcons.banknote,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel('Jenis anggaran'),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.paper2,
                      borderRadius: BorderRadius.circular(AppRadius.field),
                    ),
                    child: Row(
                      children: [
                        _segment(
                          label: 'Keseluruhan',
                          icon: LucideIcons.wallet,
                          active: overall,
                          onTap: () => controller.setOverall(true),
                        ),
                        _segment(
                          label: 'Kategori',
                          icon: LucideIcons.layers,
                          active: !overall,
                          onTap: () => controller.setOverall(false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      overall
                          ? 'Mencakup semua pengeluaran'
                          : 'Hanya pengeluaran pada kategori terpilih',
                      style: AppText.body(size: 11, color: AppColors.mut),
                    ),
                  ),
                  if (!overall) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      key: ValueKey(selected),
                      initialValue: selected,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      dropdownColor: AppColors.card,
                      style: AppText.body(size: 13.5),
                      decoration: _decoration(
                        'Kategori pengeluaran',
                        LucideIcons.tag,
                      ),
                      items: [
                        for (final category in controller.availableCategories)
                          DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                      ],
                      onChanged: (value) => controller.categoryId.value = value,
                    ),
                  ],
                  const SizedBox(height: 20),
                  _sectionLabel('Periode'),
                  Row(
                    children: [
                      _dateCard(label: 'Mulai', value: startDate, start: true),
                      const SizedBox(width: 12),
                      _dateCard(label: 'Selesai', value: endDate, start: false),
                    ],
                  ),
                  if (error != null) _errorPanel(error),
                  const SizedBox(height: 28),
                  AppButton(
                    label: 'Simpan',
                    loading: saving,
                    onPressed: saving
                        ? null
                        : () async {
                            if (await controller.save() && mounted) {
                              Get.back(result: true);
                            }
                          },
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    ),
  );
}
