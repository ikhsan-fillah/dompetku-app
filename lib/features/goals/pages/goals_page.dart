import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_bar_icon_button.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_progress_bar.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../../../core/widgets/app_toast.dart';
import '../../../core/widgets/card_actions.dart';
import '../../../core/widgets/motion.dart';
import '../../../core/widgets/swipe_actions.dart';
import '../controllers/goals_controller.dart';
import '../models/savings_goal.dart';
import '../widgets/goal_sheets.dart';

/// Halaman Tabungan: total terkumpul dan daftar tujuan. Dibuka dari pintasan
/// Beranda dan dari Profil.
class GoalsPage extends StatelessWidget {
  const GoalsPage({super.key});

  Future<void> _delete(GoalsController controller, SavingsGoal goal) async {
    final id = goal.id;
    if (id == null) return;
    final ok = await controller.delete(id);
    if (!ok) return;
    AppToast.show(
      title: 'Tujuan dihapus'.tr,
      message: '${goal.emoji} ${goal.name}',
      kind: ToastKind.undo,
      actionLabel: 'Urungkan'.tr,
      onAction: () => controller.restore(goal),
      duration: const Duration(seconds: 4),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<GoalsController>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppTitleBar(
              title: 'Tabungan'.tr,
              action: AppBarIconButton(
                tooltip: 'Tujuan baru'.tr,
                icon: LucideIcons.plus,
                onPressed: () => showGoalFormSheet(context),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Obx(() {
                final state = controller.state.value;
                switch (state.status) {
                  case ResourceStatus.idle:
                  case ResourceStatus.loading:
                    return const ListSkeleton(rows: 3);
                  case ResourceStatus.error:
                    return Center(
                      child: Text(
                        state.message ?? 'Gagal memuat tabungan.'.tr,
                        style: AppText.body(color: AppColors.spend),
                      ),
                    );
                  case ResourceStatus.empty:
                    return _Empty(onCreate: () => showGoalFormSheet(context));
                  case ResourceStatus.success:
                    final goals = controller.goals;
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.page,
                        0,
                        AppSpacing.page,
                        40,
                      ),
                      children: [
                        FadeSlideIn(
                          child: _TotalHero(
                            saved: controller.totalSaved,
                            target: controller.totalTarget,
                            count: goals.length,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.gap),
                        FadeSlideIn(
                          index: 1,
                          child: AppCard(
                            margin: EdgeInsets.zero,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: Column(
                              children: [
                                for (var i = 0; i < goals.length; i++)
                                  SwipeActions(
                                    key: ValueKey('goal-${goals[i].id}'),
                                    groupTag: 'goals',
                                    radius: 8,
                                    onEdit: () => showGoalFormSheet(
                                      context,
                                      goal: goals[i],
                                    ),
                                    onDelete: () =>
                                        _delete(controller, goals[i]),
                                    child: _GoalRow(
                                      goal: goals[i],
                                      last: i == goals.length - 1,
                                      expanded:
                                          controller.expandedId.value ==
                                          goals[i].id,
                                      onTap: () => controller.toggleExpanded(
                                        goals[i].id,
                                      ),
                                      actions: [
                                        CardAction(
                                          label: 'Setor'.tr,
                                          icon: LucideIcons.plus,
                                          onTap: () => showGoalDepositSheet(
                                            context,
                                            goals[i],
                                          ),
                                        ),
                                        CardAction(
                                          label: 'Edit'.tr,
                                          icon: LucideIcons.pencil,
                                          onTap: () => showGoalFormSheet(
                                            context,
                                            goal: goals[i],
                                          ),
                                        ),
                                        CardAction(
                                          label: 'Hapus'.tr,
                                          icon: LucideIcons.trash2,
                                          danger: true,
                                          onTap: () =>
                                              _delete(controller, goals[i]),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Ketuk tujuan untuk setor, geser untuk edit atau hapus'
                              .tr,
                          textAlign: TextAlign.center,
                          style: AppText.body(size: 11, color: AppColors.mut),
                        ),
                      ],
                    );
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalHero extends StatelessWidget {
  const _TotalHero({
    required this.saved,
    required this.target,
    required this.count,
  });

  final int saved;
  final int target;
  final int count;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.paper.withValues(alpha: 0.7);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL TERKUMPUL'.tr,
            style: AppText.label(color: muted, size: 11.5),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RollingText(
              formatIdr(saved),
              style: AppText.display(size: 32, color: AppColors.paper),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'dari @count tujuan · target @target'.trParams({
              'count': '$count',
              'target': formatIdr(target),
            }),
            style: AppText.mono(size: 11.5, color: muted),
          ),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({
    required this.goal,
    required this.last,
    required this.expanded,
    required this.onTap,
    required this.actions,
  });

  final SavingsGoal goal;
  final bool last;
  final bool expanded;
  final VoidCallback onTap;
  final List<CardAction> actions;

  Color get _color {
    if (goal.isReached || goal.percent >= 50) return AppColors.earn;
    if (goal.percent > 0) return AppColors.catFood;
    return AppColors.mut;
  }

  String get _dateNote {
    final date = goal.targetDate;
    if (goal.isReached) return 'tercapai'.tr;
    if (date == null) return 'tanpa target tanggal'.tr;
    final now = DateTime.now();
    final months = (date.year - now.year) * 12 + date.month - now.month;
    if (months <= 0) {
      return 'target @month'.trParams({
        'month': '${AppLanguage.monthShort(date.month)} ${date.year}',
      });
    }
    return months <= 6
        ? 'sisa @count bulan'.trParams({'count': '$months'})
        : 'target @month'.trParams({
            'month': '${AppLanguage.monthShort(date.month)} ${date.year}',
          });
  }

  @override
  Widget build(BuildContext context) {
    final caption = AppText.mono(
      size: 11,
      weight: FontWeight.w400,
      color: AppColors.mut,
    );
    return Container(
      decoration: last
          ? null
          : const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.line2)),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(goal.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          goal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body(
                            size: 13.5,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        '${goal.percent}%',
                        style: AppText.mono(size: 12, color: _color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AppProgressBar(
                    value: goal.progress,
                    color: _color,
                    height: 6,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '@saved / @target'.trParams({
                            'saved': formatIdrPlain(goal.savedAmount),
                            'target': formatIdrPlain(goal.targetAmount),
                          }),
                          style: caption,
                        ),
                      ),
                      Text(_dateNote, style: caption),
                    ],
                  ),
                ],
              ),
            ),
          ),
          CardActionBar(expanded: expanded, actions: actions),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          Text(
            'Belum ada tujuan tabungan'.tr,
            style: AppText.body(size: 14, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Tabung untuk sesuatu dan lihat progresnya di sini.'.tr,
            textAlign: TextAlign.center,
            style: AppText.body(size: 13, color: AppColors.ink2),
          ),
          const SizedBox(height: 16),
          AppButton(
            expand: false,
            label: 'Buat tujuan'.tr,
            icon: LucideIcons.plus,
            onPressed: onCreate,
          ),
        ],
      ),
    ),
  );
}
