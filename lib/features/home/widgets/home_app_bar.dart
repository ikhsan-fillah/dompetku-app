import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/date_label.dart';
import '../../../core/widgets/app_page_header.dart';
import '../../dashboard/controllers/dashboard_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import 'period_picker_sheet.dart';

/// App bar Beranda: sapaan di kiri, rentang tanggal di kanan.
class HomeAppBar extends StatelessWidget {
  const HomeAppBar({super.key});

  Future<void> _pickRange(
    BuildContext context,
    DashboardController dashboard,
  ) async {
    await PeriodPickerSheet.show(context, dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final profile = Get.find<ProfileController>();
    final dashboard = Get.find<DashboardController>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        8,
        AppSpacing.page,
        AppPageHeader.bottomGap,
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
                    'Halo, @name'.trParams({'name': profile.greetingName}),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(size: 11, color: AppColors.mut),
                  ),
                ),
                Text(
                  'Tally',
                  style: AppText.display(
                    size: 21,
                    height: 1.2,
                    letterSpacing: -0.21,
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
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.ink,
      ),
      child: Text(
        initial,
        style: AppText.display(size: 16, color: AppColors.paper),
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
    final radius = BorderRadius.circular(AppRadius.chip);
    return Semantics(
      button: true,
      label: 'Pilih periode, @label'.trParams({'label': label}),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: AppColors.line),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppSpacing.minTap,
                maxWidth: 190,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      LucideIcons.calendar,
                      size: 15,
                      color: AppColors.ink,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.mono(
                          size: 11.5,
                          weight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
