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
import '../services/broker_flow_analysis.dart';
import '../widgets/broker_insights.dart';
import '../widgets/broker_top_list.dart';
import '../widgets/chart_conditions.dart';
import '../widgets/group_flow_card.dart';
import '../widgets/ml_prediction_section.dart';
import '../widgets/stock_format.dart';
import '../widgets/stock_hero.dart';
import '../widgets/stock_segmented.dart';
import '../widgets/technical_section.dart';

/// Satu saham: harga terakhir, lalu tiga tab. Tab Broker berisi arah dana tiga
/// kelompok (dihitung di app) dan lima broker teratas di sisi net beli dan net
/// jual. Tab Chart berisi harga, volume, Stoch RSI, dan MACD.
/// Tab Prediksi berisi hasil model ML sebagai penyaring.
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
              (DetailTab.ml, 'Prediksi'.tr),
            ],
            onChanged: controller.selectTab,
          ),
          const SizedBox(height: AppSpacing.gap),
          switch (tab) {
            DetailTab.broker => _BrokerTab(controller: controller),
            DetailTab.chart => _ChartTab(controller: controller),
            DetailTab.ml => _MlTab(controller: controller),
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
    final bar = controller.heroBar;
    final past = controller.showingPastDay;
    final status = controller.bars.value.status;
    if (bar?.close case final int close) {
      final change = bar!.changePercent;
      final date = formatShortDate(bar.tradeDate);
      return StockHero(
        label: past
            ? '${'HARI TERPILIH'.tr} · $date'
            : bar.isIntraday
            ? '${'HARGA BERJALAN'.tr} · $date'
            : '${'PENUTUPAN'.tr} · $date',
        action: past
            ? TextButton(
                onPressed: () => controller.selectChartDay(null),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.paper,
                  minimumSize: const Size(48, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text('Hari terakhir'.tr),
              )
            : null,
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
    final analysis = controller.analysis;
    final history = controller.history.toList();
    final headline = analysis?.headline(selected);
    final period = controller.period;
    final trails = {
      for (final row in [...controller.topBuyers, ...controller.topSellers])
        row.brokerCode: ?analysis?.trailOf(row.brokerCode),
    };
    final buyers = BrokerTopList(
      side: BrokerSide.buy,
      rows: controller.topBuyers,
      totalCount: controller.buyers.length,
      rules: rules,
      trails: trails,
      topShare: analysis?.topShare(selected, BrokerSide.buy),
    );
    final sellers = BrokerTopList(
      side: BrokerSide.sell,
      rows: controller.topSellers,
      totalCount: controller.sellers.length,
      rules: rules,
      trails: trails,
      topShare: analysis?.topShare(selected, BrokerSide.sell),
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
        FadeSlideIn(
          child: GroupFlowCard(
            summary: controller.summary,
            headline: headline == null ? null : headlineText(headline),
            contextLine: switch ((headline, period)) {
              (final FlowHeadline h, (final start, final end)) => contextText(
                headline: h,
                rangeStart: start,
                rangeEnd: end,
                history: history,
              ),
              _ => null,
            },
            rangeLabel: selected,
            others: {
              for (final label in analysis?.otherLabels(selected) ?? const [])
                label: analysis!.summaries[label]!,
            },
          ),
        ),
        const SizedBox(height: 18),
        Text('Broker teratas'.tr, style: AppText.display(size: 18)),
        if (trails.isNotEmpty) ...[
          const SizedBox(height: 8),
          const TrailLegend(),
        ],
        const SizedBox(height: 10),
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
        if (analysis != null) ...[
          const SizedBox(height: AppSpacing.gap),
          FadeSlideIn(
            index: 3,
            child: BrokerHighlightsCard(analysis: analysis, selected: selected),
          ),
        ],
        const SizedBox(height: AppSpacing.gap),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.paper2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${'Total dihitung dari broker yang tampil di Broker Summary Stockbit, bukan seluruh pasar. Kelompok adalah aturan Anda, bukan fakta pasar.'.tr} ${'Bukan sinyal beli atau jual.'.tr}',
            style: AppText.body(size: 11.5, color: AppColors.ink2, height: 1.5),
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
        final history = controller.history.toList();
        final market = controller.marketHistory.toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _RangeLabel(bars: bars),
            if (history.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.gap),
              ChartConditionStrip(
                history: history,
                market: market,
                news: controller.newsScore.value,
              ),
            ],
            const SizedBox(height: AppSpacing.gap),
            TechnicalSection(
              bars: bars,
              selected: controller.chartIndex.value,
              onSelect: controller.selectChartDay,
              overlay: buildOverlay(history, bars),
              facts: chartFacts(history),
            ),
          ],
        );
    }
  });
}

/// Tab Prediksi: hasil model ML terbaru dari tabel `ml_prediction`. Selalu
/// tampil bersama tanggal model, akurasi, dan disclaimer.
class _MlTab extends StatelessWidget {
  const _MlTab({required this.controller});

  final StockDetailController controller;

  @override
  Widget build(BuildContext context) => Obx(() {
    final state = controller.ml.value;
    switch (state.status) {
      case ResourceStatus.idle:
      case ResourceStatus.loading:
        return const _TabSkeleton();
      case ResourceStatus.error:
        return AppEmptyView(
          icon: LucideIcons.wifiOff,
          message: state.message ?? 'Gagal memuat prediksi ML.'.tr,
          action: AppButton(
            label: 'Coba lagi'.tr,
            expand: false,
            onPressed: controller.loadMl,
          ),
        );
      case ResourceStatus.empty:
        return AppEmptyView(
          icon: LucideIcons.chartCandlestick,
          title: 'Belum ada prediksi ML'.tr,
          message:
              'Prediksi muncul setelah pipeline ML menilai saham ini dan model aktif tersedia.'
                  .tr,
        );
      case ResourceStatus.success:
        final prediction = state.data;
        if (prediction == null) return const _TabSkeleton();
        return FadeSlideIn(
          child: MlPredictionCard(
            prediction: prediction,
            matured: controller.mlMatured.value,
            pastPredictions: controller.mlHistory.toList(),
            cycles: controller.mlCycles.toList(),
            history: controller.history.toList(),
          ),
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
