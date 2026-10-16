import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/services/data_refresh_service.dart';
import '../pages/monthly_recap_page.dart';
import '../services/recap_calculation_service.dart';
import '../services/recap_data_loader.dart';
import 'recap_widgets.dart';

/// Baris kecil di Beranda pada tanggal 1–3: "Your {Bulan lalu} recap is ready".
/// Hanya muncul jika bulan lalu punya transaksi. Tidak ada kartu recap di Beranda.
class RecapHomeLine extends StatelessWidget {
  const RecapHomeLine({super.key, this.now});

  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final today = now ?? DateTime.now();
    if (today.day > 3) return const SizedBox.shrink();
    if (!Get.isRegistered<RecapCalculationService>()) {
      return const SizedBox.shrink();
    }
    final previous = DateTime(today.year, today.month - 1, 1);
    if (!Get.isRegistered<DataRefreshService>()) {
      return _load(today, previous);
    }
    final version = Get.find<DataRefreshService>().version;
    return Obx(() {
      version.value;
      return _load(today, previous);
    });
  }

  Widget _load(DateTime today, DateTime previous) {
    return FutureBuilder<RecapData>(
      future: loadRecapData(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
        final recap = Get.find<RecapCalculationService>().monthly(
          data.transactions,
          year: previous.year,
          month: previous.month,
          now: today,
          budgets: data.budgets,
        );
        if (!recap.hasData) return const SizedBox.shrink();
        final name = recapMonthNames[previous.month - 1];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Get.to(
                () => MonthlyRecapPage(year: previous.year, month: previous.month),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    const Icon(LucideIcons.play, size: 16, color: AppColors.ink),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your $name recap is ready',
                        style: AppText.body(size: 13, weight: FontWeight.w700),
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.mut),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
