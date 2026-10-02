import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_label.dart';
import '../../../core/utils/date_range.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../profile/controllers/profile_controller.dart';

/// App bar Beranda: sapaan di kiri, rentang tanggal di kanan.
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  Future<void> _pickRange(
    BuildContext context,
    DashboardController dashboard,
  ) async {
    final current = dashboard.range.value;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: current.start, end: current.end),
    );
    if (picked != null) {
      await dashboard.setRange(DateRange(start: picked.start, end: picked.end));
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = Get.find<ProfileController>();
    final dashboard = Get.find<DashboardController>();
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        8,
        AppSpacing.page,
        10,
      ),
      child: Row(
        children: [
          Obx(() => _Avatar(initial: profile.initial)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(
                  () => Text(
                    'Halo, ${profile.greetingName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: const Text(
                    'DompetKu',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Obx(
            () => _DateChip(
              label: DateLabel.range(dashboard.range.value),
              onTap: () => _pickRange(context, dashboard),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [AppColors.amber, AppColors.coral]),
        boxShadow: [
          BoxShadow(
            color: Color(0x4DF43F5E),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.pill);
    return Semantics(
      button: true,
      label: 'Pilih periode, $label',
      child: Material(
        color: AppColors.mint,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AppSpacing.minTap,
              maxWidth: 190,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 16,
                    color: AppColors.teal,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal,
                      ),
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
