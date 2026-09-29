import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

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

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(widget.budget == null ? 'Buat anggaran' : 'Edit anggaran')),
        body: Obx(() => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _name,
                  onChanged: (value) => controller.name.value = value,
                  decoration: const InputDecoration(labelText: 'Nama anggaran', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _amount,
                  onChanged: (value) => controller.amountDigits.value = value,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Batas anggaran (Rp)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Anggaran keseluruhan'),
                  subtitle: const Text('Mencakup semua pengeluaran'),
                  value: controller.isOverall,
                  onChanged: controller.setOverall,
                ),
                if (!controller.isOverall) DropdownButtonFormField<int>(
                  value: controller.categoryId.value,
                  decoration: const InputDecoration(labelText: 'Kategori pengeluaran', border: OutlineInputBorder()),
                  items: [for (final category in controller.availableCategories) DropdownMenuItem(value: category.id, child: Text(category.name))],
                  onChanged: (value) => controller.categoryId.value = value,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tanggal mulai'),
                  subtitle: Text(_date(controller.startDate.value)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () => _pickDate(true),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Tanggal selesai'),
                  subtitle: Text(_date(controller.endDate.value)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: () => _pickDate(false),
                ),
                if (controller.error.value != null) Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(controller.error.value!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: controller.saving.value ? null : () async {
                    if (await controller.save() && mounted) Get.back(result: true);
                  },
                  child: controller.saving.value ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Simpan'),
                ),
              ],
            )),
      );
}
