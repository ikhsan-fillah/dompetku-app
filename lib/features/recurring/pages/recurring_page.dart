import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatter.dart';
import '../controllers/recurring_controller.dart';
import 'recurring_add_sheet.dart';
import '../models/recurring_rule.dart';

/// Daftar recurring: item aktif/nonaktif lewat sakelar. Nonaktif tidak dihapus.
class RecurringPage extends StatelessWidget {
  const RecurringPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<RecurringController>();
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        elevation: 0,
        title: Text('Recurring', style: AppText.display(size: 26)),
        actions: [
          IconButton(
            tooltip: 'Add recurring',
            icon: const Icon(LucideIcons.plus, color: AppColors.ink),
            onPressed: () async {
              final saved = await showRecurringAddSheet(context);
              if (saved) await controller.load();
            },
          ),
        ],
      ),
      body: Obx(() {
        final state = controller.state.value;
        switch (state.status) {
          case ResourceStatus.idle:
          case ResourceStatus.loading:
            return const Center(child: CircularProgressIndicator());
          case ResourceStatus.error:
            return Center(
              child: Text(
                state.message ?? 'Gagal memuat recurring.',
                style: AppText.body(color: AppColors.spend),
              ),
            );
          case ResourceStatus.empty:
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No recurring items yet. Add rent, subscriptions, or bills.',
                  textAlign: TextAlign.center,
                  style: AppText.body(size: 13, color: AppColors.mut),
                ),
              ),
            );
          case ResourceStatus.success:
            final rules = state.data ?? const <RecurringRule>[];
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rules.length,
              itemBuilder: (context, index) => _RuleTile(
                rule: rules[index],
                onToggle: (value) =>
                    controller.setActive(rules[index].id!, value),
              ),
            );
        }
      }),
    );
  }
}

class _RuleTile extends StatelessWidget {
  const _RuleTile({required this.rule, required this.onToggle});

  final RecurringRule rule;
  final ValueChanged<bool> onToggle;

  String get _schedule => switch (rule.frequency) {
    RecurringFrequency.monthly => 'Monthly · due ${_ordinal(rule.dayOfMonth ?? rule.startDate.day)}',
    RecurringFrequency.weekly => 'Weekly',
    RecurringFrequency.yearly => 'Yearly',
  };

  String get _mode => rule.mode == RecurringMode.ask
      ? 'Ask me first'
      : 'Record automatically';

  static String _ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    return switch (day % 10) {
      1 => '${day}st',
      2 => '${day}nd',
      3 => '${day}rd',
      _ => '${day}th',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule.name, style: AppText.body(size: 13, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  '$_schedule · $_mode',
                  style: AppText.body(size: 11, color: AppColors.mut),
                ),
              ],
            ),
          ),
          Text(
            formatIdr(rule.amount),
            style: AppText.mono(size: 12.5, color: AppColors.ink),
          ),
          const SizedBox(width: 8),
          Switch(
            value: rule.isActive,
            activeTrackColor: AppColors.ink,
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}
