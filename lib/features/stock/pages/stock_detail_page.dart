import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../../../core/widgets/motion.dart';
import '../controllers/stock_detail_controller.dart';
import '../models/broker_group.dart';
import '../models/broker_range_row.dart';
import '../widgets/group_flow_card.dart';
import '../widgets/stock_format.dart';

/// Net beli dan net jual per broker untuk satu saham, dengan total per
/// kelompok (ritel, bandar, asing) yang dihitung di app.
class StockDetailPage extends StatelessWidget {
  const StockDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StockDetailController>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            AppTitleBar(title: controller.ticker),
            const SizedBox(height: 14),
            Expanded(
              child: Obx(() {
                final state = controller.state.value;
                switch (state.status) {
                  case ResourceStatus.idle:
                  case ResourceStatus.loading:
                    return const ListSkeleton(rows: 4);
                  case ResourceStatus.error:
                    return AppEmptyView(
                      icon: LucideIcons.wifiOff,
                      message: state.message ?? 'Gagal memuat data broker.'.tr,
                      action: AppButton(
                        label: 'Coba lagi'.tr,
                        expand: false,
                        onPressed: controller.load,
                      ),
                    );
                  case ResourceStatus.empty:
                    return AppEmptyView(
                      icon: LucideIcons.chartBar,
                      title: 'Belum ada data broker'.tr,
                      message:
                          'Data muncul setelah otomatisasi Stockbit mengisinya.'
                              .tr,
                    );
                  case ResourceStatus.success:
                    return _Body(controller: controller);
                }
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.controller});

  final StockDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.range.value;
      final rows = controller.rowsInRange;
      final rules = controller.data?.rules ?? const BrokerGroupRules.empty();
      final periodText = switch (controller.period) {
        (final start, final end) =>
          '${formatShortDate(start)} - ${formatShortDate(end)}',
        null => 'Tidak ada data untuk rentang ini.'.tr,
      };
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          0,
          AppSpacing.page,
          40,
        ),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final label in brokerRangeLabels)
                AppChip(
                  label: label,
                  selected: label == selected,
                  onTap: () => controller.selectRange(label),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(periodText, style: AppText.body(size: 11, color: AppColors.mut)),
          const SizedBox(height: AppSpacing.gap),
          FadeSlideIn(child: GroupFlowCard(summary: controller.summary)),
          const SizedBox(height: 10),
          Text(
            'Total dihitung dari broker yang tampil di Broker Summary Stockbit, bukan seluruh pasar. Kelompok adalah aturan Anda, bukan fakta pasar.'
                .tr,
            style: AppText.body(size: 11, color: AppColors.mut, height: 1.4),
          ),
          const SizedBox(height: 18),
          Text('Per broker'.tr, style: AppText.display(size: 18)),
          const SizedBox(height: 8),
          if (rows.isNotEmpty)
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
                    for (final row in rows)
                      _BrokerRow(
                        row: row,
                        group: rules.groupOf(row.brokerCode),
                      ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _BrokerRow extends StatelessWidget {
  const _BrokerRow({required this.row, required this.group});

  final BrokerRangeRow row;
  final BrokerGroup? group;

  @override
  Widget build(BuildContext context) {
    final value = row.signedValueIdr;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              row.brokerCode,
              style: AppText.mono(size: 14, weight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(switch (group) {
              final BrokerGroup known => known.label.tr,
              null => 'belum diklasifikasi'.tr,
            }, style: AppText.body(size: 11, color: AppColors.mut)),
          ),
          Text(
            formatBrokerValue(value, approx: row.isApprox),
            style: AppText.mono(size: 13, color: netColor(value)),
          ),
        ],
      ),
    );
  }
}
