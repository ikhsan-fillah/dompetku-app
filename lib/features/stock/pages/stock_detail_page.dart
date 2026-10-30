import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/state/resource_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_skeleton.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/widgets/app_title_bar.dart';
import '../../../core/widgets/motion.dart';
import '../controllers/stock_detail_controller.dart';
import '../models/broker_group.dart';
import '../models/broker_range_row.dart';
import '../models/daily_bar.dart';
import '../widgets/broker_top_list.dart';
import '../widgets/group_flow_card.dart';
import '../widgets/stock_format.dart';
import '../widgets/stock_hero.dart';
import '../widgets/stock_segmented.dart';
import '../widgets/technical_section.dart';

/// Satu saham: harga terakhir, lalu dua tab. Tab Broker berisi arah dana tiga
/// kelompok (dihitung di app) dan lima broker teratas di sisi net beli dan net
/// jual. Tab Chart berisi harga, volume, Stoch RSI, dan MACD.
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
            Expanded(child: _Body(controller: controller)),
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
      final tab = controller.tab.value;
      return ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          0,
          AppSpacing.page,
          40,
        ),
        children: [
          FadeSlideIn(child: _QuoteHero(controller: controller)),
          const SizedBox(height: AppSpacing.gap),
          StockSegmented<DetailTab>(
            value: tab,
            options: [
              (DetailTab.broker, 'Broker'.tr),
              (DetailTab.chart, 'Chart'.tr),
            ],
            onChanged: controller.selectTab,
          ),
          const SizedBox(height: AppSpacing.gap),
          switch (tab) {
            DetailTab.broker => _BrokerTab(controller: controller),
            DetailTab.chart => _ChartTab(controller: controller),
          },
        ],
      );
    });
  }
}

/// Blok tinta: penutupan terakhir dan perubahannya, atau penjelasan singkat
/// bila harga belum terisi.
class _QuoteHero extends StatelessWidget {
  const _QuoteHero({required this.controller});

  final StockDetailController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final bar = controller.latestBar;
    final status = controller.bars.value.status;
    if (bar?.close case final int close) {
      final change = bar!.changePercent;
      final date = formatShortDate(bar.tradeDate);
      return StockHero(
        label: bar.isIntraday
            ? '${'HARGA BERJALAN'.tr} · $date'
            : '${'PENUTUPAN'.tr} · $date',
        live: bar.isIntraday,
        title: 'Rp ${formatPrice(close)}',
        trailing: change == null
            ? null
            : ChangePill(percent: change, text: formatPercent(change)),
        caption: bar.prevClose == null
            ? 'Volume dalam lot'.tr
            : 'Penutupan kemarin @price · volume dalam lot'.trParams({
                'price': formatPrice(bar.prevClose!),
              }),
        footer: HeroStats(items: _stats(bar)),
      );
    }
    final waiting =
        status == ResourceStatus.idle || status == ResourceStatus.loading;
    return StockHero(
      label: 'HARGA'.tr,
      title: waiting ? 'Memuat harga'.tr : 'Harga belum ada'.tr,
      caption: waiting
          ? 'Mengambil data harian dari Supabase.'.tr
          : 'Chart dan indikator muncul setelah data harian saham ini terisi. Data broker sudah bisa dilihat di tab Broker.'
                .tr,
    );
  });

  List<(String, String)> _stats(DailyBar bar) {
    String price(int? value) => value == null ? '-' : formatPrice(value);
    return [
      ('BUKA'.tr, price(bar.open)),
      ('TERTINGGI'.tr, price(bar.high)),
      ('TERENDAH'.tr, price(bar.low)),
      ('VOLUME'.tr, bar.volumeLot == null ? '-' : formatLot(bar.volumeLot!)),
    ];
  }
}

class _BrokerTab extends StatelessWidget {
  const _BrokerTab({required this.controller});

  final StockDetailController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final state = controller.state.value;
    switch (state.status) {
      case ResourceStatus.idle:
      case ResourceStatus.loading:
        return const _TabSkeleton();
      case ResourceStatus.error:
        return AppEmptyView(
          icon: LucideIcons.wifiOff,
          message: state.message ?? 'Gagal memuat data broker.'.tr,
          action: AppButton(
            label: 'Coba lagi'.tr,
            expand: false,
            onPressed: controller.loadBrokers,
          ),
        );
      case ResourceStatus.empty:
        return AppEmptyView(
          icon: LucideIcons.chartBar,
          title: 'Belum ada data broker'.tr,
          message: 'Data muncul setelah otomatisasi Stockbit mengisinya.'.tr,
        );
      case ResourceStatus.success:
        return _BrokerContent(controller: controller);
    }
  });
}

class _BrokerContent extends StatelessWidget {
  const _BrokerContent({required this.controller});

  final StockDetailController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final selected = controller.range.value;
    final rules = controller.data?.rules ?? const BrokerGroupRules.empty();
    final periodText = switch (controller.period) {
      (final start, final end) =>
        '${formatShortDate(start)} - ${formatShortDate(end)}',
      null => 'Tidak ada data untuk rentang ini.'.tr,
    };
    final buyers = BrokerTopList(
      side: BrokerSide.buy,
      rows: controller.topBuyers,
      totalCount: controller.buyers.length,
      rules: rules,
    );
    final sellers = BrokerTopList(
      side: BrokerSide.sell,
      rows: controller.topSellers,
      totalCount: controller.sellers.length,
      rules: rules,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
        Text('Broker teratas'.tr, style: AppText.display(size: 18)),
        const SizedBox(height: 8),
        // Net beli dan net jual selalu bersampingan, juga di layar HP.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: FadeSlideIn(index: 1, child: buyers)),
              const SizedBox(width: 10),
              Expanded(child: FadeSlideIn(index: 2, child: sellers)),
            ],
          ),
        ),
      ],
    );
  });
}

class _ChartTab extends StatelessWidget {
  const _ChartTab({required this.controller});

  final StockDetailController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final state = controller.bars.value;
    switch (state.status) {
      case ResourceStatus.idle:
      case ResourceStatus.loading:
        return const _TabSkeleton();
      case ResourceStatus.error:
        return AppEmptyView(
          icon: LucideIcons.wifiOff,
          message: state.message ?? 'Gagal memuat data harga.'.tr,
          action: AppButton(
            label: 'Coba lagi'.tr,
            expand: false,
            onPressed: controller.loadBars,
          ),
        );
      case ResourceStatus.empty:
        return AppEmptyView(
          icon: LucideIcons.chartCandlestick,
          title: 'Belum ada data harga'.tr,
          message:
              'Chart, volume, Stoch RSI, dan MACD muncul setelah otomatisasi Stockbit mengisi data harian saham ini.'
                  .tr,
        );
      case ResourceStatus.success:
        final bars = controller.visibleBars;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RangeLabel(bars: bars),
            const SizedBox(height: AppSpacing.gap),
            TechnicalSection(bars: bars),
          ],
        );
    }
  });
}

/// Rentang chart yang tetap satu bulan: label 1M, jumlah hari bursa, dan
/// tanggal awal sampai akhir.
class _RangeLabel extends StatelessWidget {
  const _RangeLabel({required this.bars});

  final List<DailyBar> bars;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '1M',
            style: AppText.body(
              size: 12,
              weight: FontWeight.w700,
              color: AppColors.paper,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '@count hari bursa · @start sampai @end'.trParams({
              'count': '${bars.length}',
              'start': formatDayMonth(bars.first.tradeDate),
              'end': formatShortDate(bars.last.tradeDate),
            }),
            style: AppText.body(size: 11.5, color: AppColors.mut),
          ),
        ),
      ],
    );
  }
}

/// Kerangka isi tab selama data dimuat. Ada di dalam ListView halaman, jadi
/// tidak memakai ListSkeleton yang membawa ListView sendiri.
class _TabSkeleton extends StatelessWidget {
  const _TabSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonShimmer(
      child: Column(
        children: [
          SkeletonBox(height: 190),
          SizedBox(height: AppSpacing.gap),
          SkeletonBox(height: 140),
          SizedBox(height: AppSpacing.gap),
          SkeletonBox(height: 140),
        ],
      ),
    );
  }
}
