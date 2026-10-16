import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatter.dart';
import '../../transaction/repositories/transaction_repository.dart';
import '../services/recap_calculation_service.dart';

/// Recap satu bulan: total, rata-rata harian, dan kategori teratas.
class MonthlyRecapPage extends StatelessWidget {
  const MonthlyRecapPage({super.key, required this.year, required this.month});

  final int year;
  final int month;

  @override
  Widget build(BuildContext context) {
    final recaps = Get.find<RecapCalculationService>();
    final transactions = Get.find<TransactionRepository>();
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: FutureBuilder(
          future: transactions.getAll(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.paper),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Gagal memuat recap.',
                  style: AppText.body(color: AppColors.paper),
                ),
              );
            }
            final recap = recaps.monthly(
              snapshot.data ?? const [],
              year: year,
              month: month,
              now: DateTime.now(),
            );
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.paper),
                        onPressed: () => Get.back(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You spent',
                    style: AppText.body(
                      size: 13,
                      color: AppColors.paper.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatIdr(recap.spent),
                    style: AppText.display(size: 38, color: AppColors.paper),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "That's ${formatIdr(recap.dailyAverage)} a day${recap.isSoFar ? ' so far' : ''}.",
                    style: AppText.body(
                      size: 13,
                      color: AppColors.paper.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (recap.topCategories.isNotEmpty)
                    Text(
                      'Top category · ${formatIdr(recap.topCategories.first.total)}',
                      style: AppText.body(color: AppColors.paper),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
