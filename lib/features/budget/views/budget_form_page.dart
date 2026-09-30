import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../controllers/budget_form_controller.dart';
import '../models/budget_model.dart';

const _bg = Color(0xFFF6FAF9);
const _teal = Color(0xFF0F766E);
const _emerald = Color(0xFF10B981);
const _mint = Color(0xFFCCFBF1);
const _coral = Color(0xFFF43F5E);
const _coralSoft = Color(0xFFFFE4E9);
const _ink = Color(0xFF1F2937);
const _muted = Color(0xFF64748B);
const _border = Color(0xFFE2E8F0);

const _shadow = [
  BoxShadow(color: Color(0x170F766E), blurRadius: 22, offset: Offset(0, 6)),
];

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
    final current = start ? controller.startDate.value : controller.endDate.value;
    final selected = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null) controller.setDates(start: start ? selected : null, end: start ? null : selected);
  }

  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  InputDecoration _decoration(String label, IconData icon) {
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _muted),
      floatingLabelStyle: const TextStyle(color: _teal, fontWeight: FontWeight.w600),
      prefixIcon: Icon(icon, color: _teal),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border(_border),
      enabledBorder: border(_border),
      focusedBorder: border(_teal, 1.6),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(
          text,
          style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      );

  Widget _segment({
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              gradient: active ? const LinearGradient(colors: [_teal, _emerald]) : null,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: active ? Colors.white : _muted),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: active ? Colors.white : _muted,
                    fontSize: 13.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _dateCard({required String label, required DateTime value, required bool start}) => Expanded(
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _pickDate(start),
            child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(9)),
                      child: const Icon(Icons.calendar_today_outlined, size: 15, color: _teal),
                    ),
                    const SizedBox(width: 8),
                    Text(label, style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 10),
                  Text(
                    _date(value),
                    style: const TextStyle(color: _ink, fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  Widget _errorPanel(String message) => Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _coralSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x33F43F5E)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.error_outline_rounded, color: _coral, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: _coral, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ]),
      );

  Widget _saveButton(bool saving) => Opacity(
        opacity: saving ? 0.7 : 1,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [_teal, _emerald]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0x330F766E), blurRadius: 18, offset: Offset(0, 6))],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: saving
                  ? null
                  : () async {
                      if (await controller.save() && mounted) Get.back(result: true);
                    },
              child: SizedBox(
                height: 54,
                child: Center(
                  child: saving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Simpan',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          leadingWidth: 64,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              elevation: 0,
              shadowColor: const Color(0x170F766E),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Get.back(),
                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _teal),
              ),
            ),
          ),
          title: Text(
            widget.budget == null ? 'Buat anggaran' : 'Edit anggaran',
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
        ),
        body: Obx(() {
          final selected = controller.availableCategories.any((c) => c.id == controller.categoryId.value)
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
                decoration: _decoration('Nama anggaran', Icons.edit_note_rounded),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amount,
                onChanged: (value) => controller.amountDigits.value = value,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _decoration('Batas anggaran (Rp)', Icons.payments_outlined),
              ),
              const SizedBox(height: 20),
              _sectionLabel('Jenis anggaran'),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _shadow,
                ),
                child: Row(children: [
                  _segment(
                    label: 'Keseluruhan',
                    icon: Icons.account_balance_wallet_outlined,
                    active: overall,
                    onTap: () => controller.setOverall(true),
                  ),
                  _segment(
                    label: 'Kategori',
                    icon: Icons.category_outlined,
                    active: !overall,
                    onTap: () => controller.setOverall(false),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  overall ? 'Mencakup semua pengeluaran' : 'Hanya pengeluaran pada kategori terpilih',
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ),
              if (!overall) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  key: ValueKey(selected),
                  initialValue: selected,
                  borderRadius: BorderRadius.circular(14),
                  dropdownColor: Colors.white,
                  decoration: _decoration('Kategori pengeluaran', Icons.sell_outlined),
                  items: [
                    for (final category in controller.availableCategories)
                      DropdownMenuItem(value: category.id, child: Text(category.name)),
                  ],
                  onChanged: (value) => controller.categoryId.value = value,
                ),
              ],
              const SizedBox(height: 20),
              _sectionLabel('Periode'),
              Row(children: [
                _dateCard(label: 'Mulai', value: startDate, start: true),
                const SizedBox(width: 12),
                _dateCard(label: 'Selesai', value: endDate, start: false),
              ]),
              if (error != null) _errorPanel(error),
              const SizedBox(height: 28),
              _saveButton(saving),
            ],
          );
        }),
      );
}
