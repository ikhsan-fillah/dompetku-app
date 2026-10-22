import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/services/data_refresh_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../repositories/draft_repository.dart';

/// Banner "N drafts waiting for you". Hanya tampil bila ada draft pending.
class DraftsBanner extends StatelessWidget {
  const DraftsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<DraftRepository>()) return const SizedBox.shrink();
    final repository = Get.find<DraftRepository>();
    final version = Get.isRegistered<DataRefreshService>()
        ? Get.find<DataRefreshService>().version
        : null;
    return Obx(() {
      version?.value;
      return FutureBuilder<int>(
        future: repository.countPending(),
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          if (count == 0) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Material(
              color: AppColors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.line),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => Get.toNamed(AppRoutes.drafts),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.bell,
                        size: 18,
                        color: AppColors.ink,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          count == 1
                              ? '1 draf menunggumu'.tr
                              : '@count draf menunggumu'.trParams({
                                  'count': '$count',
                                }),
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(
                        LucideIcons.chevronRight,
                        size: 18,
                        color: AppColors.mut,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    });
  }
}
