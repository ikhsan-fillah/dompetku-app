import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_label.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_date_picker.dart';
import '../../../core/widgets/motion.dart';
import '../controllers/goals_controller.dart';
import '../models/savings_goal.dart';

const _emojis = ['💻', '🏝️', '🛡️', '🏠', '🚗', '🎓', '💍', '📱', '✈️', '🎁'];

/// Lembar tambah/ubah tujuan tabungan.
Future<bool> showGoalFormSheet(
  BuildContext context, {
  SavingsGoal? goal,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _GoalForm(goal: goal),
    ),
  );
  return saved == true;
}

/// Lembar setor atau ambil uang dari tujuan. Merayakan bila target tercapai.
Future<void> showGoalDepositSheet(
  BuildContext context,
  SavingsGoal goal,
) async {
  final reached = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
      ),
      child: _DepositForm(goal: goal),
    ),
  );
  if (reached == true && context.mounted) {
    await showGoalReachedDialog(context, goal);
  }
}

/// Perayaan kecil, sekali saat tujuan pertama kali mencapai 100%.
Future<void> showGoalReachedDialog(BuildContext context, SavingsGoal goal) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.hero),
        side: const BorderSide(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.4, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.elasticOut,
              builder: (_, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: const Text('🎉', style: TextStyle(fontSize: 52)),
            ),
            const SizedBox(height: 10),
            Text(
              '@name tercapai!'.trParams({'name': goal.name}),
              textAlign: TextAlign.center,
              style: AppText.display(size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              'Target @amount sudah terkumpul.'.trParams({
                'amount': formatIdr(goal.targetAmount),
              }),
              textAlign: TextAlign.center,
              style: AppText.body(size: 13, color: AppColors.ink2),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'Mantap'.tr,
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Format ribuan saat mengetik nominal (1.500.000).
class _ThousandsFormatter extends TextInputFormatter {
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

int _digits(TextEditingController controller) =>
    int.tryParse(controller.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

InputDecoration _decoration(String label, {String? prefix}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.field),
    borderSide: BorderSide(color: color),
  );
  return InputDecoration(
    labelText: label,
    prefixText: prefix,
    filled: true,
    fillColor: AppColors.card,
    labelStyle: AppText.body(size: 12.5, color: AppColors.ink2),
    enabledBorder: border(AppColors.line),
    focusedBorder: border(AppColors.ink),
    border: border(AppColors.line),
  );
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(text, style: AppText.display(size: 20))),
      IconButton(
        tooltip: 'Tutup'.tr,
        onPressed: () => Navigator.of(context).pop(false),
        icon: const Icon(LucideIcons.x, size: 18, color: AppColors.ink),
      ),
    ],
  );
}

class _GoalForm extends StatefulWidget {
  const _GoalForm({this.goal});

  final SavingsGoal? goal;

  @override
  State<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<_GoalForm> {
  late final _name = TextEditingController(text: widget.goal?.name ?? '');
  late final _target = TextEditingController(
    text: widget.goal == null ? '' : formatIdrPlain(widget.goal!.targetAmount),
  );
  late final _saved = TextEditingController(
    text: widget.goal == null || widget.goal!.savedAmount == 0
        ? ''
        : formatIdrPlain(widget.goal!.savedAmount),
  );
  late String _emoji = widget.goal?.emoji ?? _emojis.first;
  late DateTime? _date = widget.goal?.targetDate;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _saved.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context,
      initialDate: _date ?? DateTime(now.year, now.month + 3, now.day),
      firstDate: now,
      lastDate: DateTime(now.year + 10),
      title: 'Target tanggal'.tr,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final target = _digits(_target);
    if (name.isEmpty) {
      setState(() => _error = 'Nama tujuan wajib diisi.'.tr);
      return;
    }
    if (target <= 0) {
      setState(() => _error = 'Target harus lebih dari nol.'.tr);
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    final now = DateTime.now();
    final base =
        widget.goal ??
        SavingsGoal(
          name: name,
          emoji: _emoji,
          targetAmount: target,
          createdAt: now,
          updatedAt: now,
        );
    final goal = base.copyWith(
      name: name,
      emoji: _emoji,
      targetAmount: target,
      savedAmount: _digits(_saved),
      targetDate: _date,
      clearTargetDate: _date == null,
    );
    final ok = await Get.find<GoalsController>().save(goal);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetTitle(
            widget.goal == null ? 'Tujuan baru'.tr : 'Edit tujuan'.tr,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final emoji in _emojis)
                Semantics(
                  button: true,
                  selected: emoji == _emoji,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      setState(() => _emoji = emoji);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: emoji == _emoji
                            ? AppColors.paper2
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: emoji == _emoji
                              ? AppColors.ink
                              : AppColors.line,
                          width: emoji == _emoji ? 1.5 : 1,
                        ),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 20)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            decoration: _decoration('Nama tujuan, contoh: Laptop baru'.tr),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('goal-target'),
            controller: _target,
            keyboardType: TextInputType.number,
            inputFormatters: [_ThousandsFormatter()],
            decoration: _decoration('Target'.tr, prefix: 'Rp '),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('goal-saved'),
            controller: _saved,
            keyboardType: TextInputType.number,
            inputFormatters: [_ThousandsFormatter()],
            decoration: _decoration(
              'Sudah terkumpul (opsional)'.tr,
              prefix: 'Rp ',
            ),
          ),
          const SizedBox(height: 10),
          Material(
            color: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.field),
              side: const BorderSide(color: AppColors.line),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.field),
              onTap: _pickDate,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.calendar,
                      size: 18,
                      color: AppColors.ink2,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _date == null
                            ? 'Target tanggal (opsional)'.tr
                            : DateLabel.day(_date!),
                        style: AppText.body(
                          size: 13.5,
                          color: _date == null ? AppColors.mut : AppColors.ink,
                        ),
                      ),
                    ),
                    if (_date != null)
                      IconButton(
                        tooltip: 'Hapus tanggal'.tr,
                        onPressed: () => setState(() => _date = null),
                        icon: const Icon(
                          LucideIcons.x,
                          size: 16,
                          color: AppColors.mut,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: AppText.body(
                size: 12,
                weight: FontWeight.w700,
                color: AppColors.spend,
              ),
            ),
          ],
          const SizedBox(height: 16),
          AppButton(
            label: widget.goal == null
                ? 'Simpan tujuan'.tr
                : 'Simpan perubahan'.tr,
            icon: LucideIcons.check,
            loading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _DepositForm extends StatefulWidget {
  const _DepositForm({required this.goal});

  final SavingsGoal goal;

  @override
  State<_DepositForm> createState() => _DepositFormState();
}

class _DepositFormState extends State<_DepositForm> {
  final _amount = TextEditingController();
  bool _withdraw = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = _digits(_amount);
    if (amount <= 0) {
      setState(() => _error = 'Nominal harus lebih dari nol.'.tr);
      return;
    }
    final reached = await Get.find<GoalsController>().deposit(
      widget.goal,
      _withdraw ? -amount : amount,
    );
    if (mounted) Navigator.of(context).pop(reached);
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetTitle('${goal.emoji}  ${goal.name}'),
          Text(
            '@saved dari @target'.trParams({
              'saved': formatIdr(goal.savedAmount),
              'target': formatIdr(goal.targetAmount),
            }),
            style: AppText.mono(size: 12, color: AppColors.ink2),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.paper2,
              borderRadius: BorderRadius.circular(AppRadius.field),
            ),
            child: Row(
              children: [
                for (final withdraw in [false, true])
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _withdraw = withdraw),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _withdraw == withdraw
                              ? (withdraw ? AppColors.spend : AppColors.earn)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.chip),
                        ),
                        child: Text(
                          withdraw ? 'Ambil'.tr : 'Setor'.tr,
                          style: AppText.body(
                            size: 12.5,
                            weight: FontWeight.w700,
                            color: _withdraw == withdraw
                                ? Colors.white
                                : AppColors.mut,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('goal-deposit'),
            controller: _amount,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [_ThousandsFormatter()],
            decoration: _decoration('Nominal'.tr, prefix: 'Rp '),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: AppText.body(
                size: 12,
                weight: FontWeight.w700,
                color: AppColors.spend,
              ),
            ),
          ],
          const SizedBox(height: 16),
          AppButton(
            label: _withdraw ? 'Ambil dari tabungan'.tr : 'Tambah setoran'.tr,
            icon: LucideIcons.check,
            onPressed: _save,
          ),
          const SizedBox(height: 6),
          Center(
            child: PopOnChange(
              trigger: _withdraw,
              child: Text(
                _withdraw
                    ? 'Mengurangi jumlah yang terkumpul'.tr
                    : 'Menambah jumlah yang terkumpul'.tr,
                style: AppText.body(size: 11.5, color: AppColors.mut),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
