import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/widgets/app_card.dart';
import '../controllers/spending_trend_controller.dart';
import '../models/monthly_trend.dart';

/// Kartu "Tren pengeluaran": satu batang per hari dalam bulan terpilih,
/// pita dua warna per pekan, garis rata-rata, dan total di bawahnya. Mengetuk
/// batang menampilkan tanggal dan nominalnya.
class SpendingTrendCard extends StatelessWidget {
  const SpendingTrendCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SpendingTrendController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<SpendingTrendController>();
    return AppCard(
      child: Obx(() {
        final trend = controller.trend.value;
        if (trend == null) {
          return _Header(controller: controller, month: null, loading: true);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(controller: controller, month: trend.month),
            const SizedBox(height: 10),
            _InfoLine(
              trend: trend,
              showHint: controller.selectedDay.value == null && trend.total > 0,
            ),
            SpendingTrendChart(
              trend: trend,
              selected: controller.selectedDay.value,
              onTapDay: controller.selectDay,
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: AppColors.line2),
            const SizedBox(height: 10),
            _TotalLine(trend: trend),
          ],
        );
      }),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.month,
    this.loading = false,
  });

  final SpendingTrendController controller;
  final DateTime? month;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Tren pengeluaran'.tr,
            style: AppText.body(
              size: 13,
              weight: FontWeight.w700,
              letterSpacing: 0.13,
            ),
          ),
        ),
        _NavButton(
          icon: LucideIcons.chevronLeft,
          tooltip: 'Bulan sebelumnya'.tr,
          onTap: loading || !controller.canGoPrevious
              ? null
              : controller.previousMonth,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 68),
          child: Text(
            month == null
                ? ''
                : '${AppLanguage.monthShort(month!.month)} ${month!.year}',
            textAlign: TextAlign.center,
            style: AppText.body(size: 12.5, weight: FontWeight.w700),
          ),
        ),
        _NavButton(
          icon: LucideIcons.chevronRight,
          tooltip: 'Bulan berikutnya'.tr,
          onTap: loading || !controller.canGoNext ? null : controller.nextMonth,
        ),
      ],
    );
  }
}

/// Tombol panah bulan: gaya sama dengan tombol ikon app bar, redup bila mati.
class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.smallButton),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.smallButton),
            border: Border.all(
              color: enabled ? AppColors.line : AppColors.line2,
            ),
          ),
          child: Icon(
            icon,
            size: 16,
            color: enabled ? AppColors.ink : const Color(0xFFC9C1AE),
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.trend, required this.showHint});

  final MonthlyTrend trend;
  final bool showHint;

  @override
  Widget build(BuildContext context) {
    final style = AppText.mono(
      size: 11,
      weight: FontWeight.w400,
      color: AppColors.ink2,
      letterSpacing: 0,
    );
    return Row(
      children: [
        Expanded(
          child: Text(
            'Rata-rata @amount per hari'.trParams({
              'amount': formatIdr(trend.average.round()),
            }),
            style: style,
          ),
        ),
        if (showHint) Text('Ketuk batang'.tr, style: style),
      ],
    );
  }
}

class _TotalLine extends StatelessWidget {
  const _TotalLine({required this.trend});

  final MonthlyTrend trend;

  @override
  Widget build(BuildContext context) {
    final label = trend.isInProgress
        ? 'Total · @elapsed dari @days hari'.trParams({
            'elapsed': '${trend.elapsedDays}',
            'days': '${trend.daysInMonth}',
          })
        : 'Total · @days hari'.trParams({'days': '${trend.daysInMonth}'});
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: AppText.body(size: 11.5, color: AppColors.ink2),
          ),
        ),
        Text(
          formatIdr(trend.total),
          style: AppText.mono(
            size: 13,
            weight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

/// Batang per hari dengan pita pekan, garis rata-rata, dan gelembung hari
/// terpilih. Terpisah dari kartu supaya mudah dites.
class SpendingTrendChart extends StatelessWidget {
  const SpendingTrendChart({
    super.key,
    required this.trend,
    required this.selected,
    required this.onTapDay,
  });

  final MonthlyTrend trend;
  final int? selected;
  final ValueChanged<int> onTapDay;

  static const chartHeight = 120.0;
  static const _bubbleRoom = 34.0;

  Color _barColor(int index, int? peakIndex) {
    if (index >= trend.elapsedDays) return AppColors.line2;
    if (trend.daily[index] == 0) return AppColors.line;
    if (index == selected) return AppColors.ink;
    if (index == peakIndex) return AppColors.spend;
    if (trend.isCurrent && index == trend.elapsedDays - 1) {
      return AppColors.ink2;
    }
    return AppColors.ink.withValues(alpha: 0.32);
  }

  double _barHeight(int index) {
    final peak = trend.peakAmount;
    final value = trend.daily[index];
    if (index >= trend.elapsedDays || value == 0 || peak == 0) return 2;
    return (value / peak * chartHeight).clamp(3.0, chartHeight);
  }

  String _dateLabel(int index) =>
      '${index + 1} ${AppLanguage.monthShort(trend.month.month)}';

  @override
  Widget build(BuildContext context) {
    final peakIndex = trend.peakIndex;
    final days = trend.daysInMonth;
    final average = trend.average;
    return Padding(
      padding: const EdgeInsets.only(top: _bubbleRoom),
      child: Column(
        children: [
          SizedBox(
            height: chartHeight,
            child: LayoutBuilder(
              builder: (context, box) => Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < days; i++)
                        Expanded(
                          child: _BarSlot(
                            key: ValueKey('trend-bar-$i'),
                            band: trend.weekOf(i).isEven,
                            height: _barHeight(i),
                            color: _barColor(i, peakIndex),
                            semanticLabel: i < trend.elapsedDays
                                ? '@date · @amount'.trParams({
                                    'date': _dateLabel(i),
                                    'amount': formatIdr(trend.daily[i]),
                                  })
                                : _dateLabel(i),
                            onTap: i < trend.elapsedDays
                                ? () => onTapDay(i)
                                : null,
                          ),
                        ),
                    ],
                  ),
                  if (trend.peakAmount > 0 && average > 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: (average / trend.peakAmount * chartHeight).clamp(
                        0.0,
                        chartHeight,
                      ),
                      child: IgnorePointer(
                        child: CustomPaint(
                          size: const Size(double.infinity, 2),
                          painter: _DashedLinePainter(),
                        ),
                      ),
                    ),
                  if (selected != null && selected! < trend.elapsedDays)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomSingleChildLayout(
                          delegate: _BubbleLayout(
                            centerX: (selected! + 0.5) / days * box.maxWidth,
                            barTop: chartHeight - _barHeight(selected!),
                          ),
                          child: _Bubble(
                            text: '@date · @amount'.trParams({
                              'date': _dateLabel(selected!),
                              'amount': formatIdr(trend.daily[selected!]),
                            }),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (var i = 0; i < days; i++)
                Expanded(
                  child: Text(
                    trend.isMonday(i) ? '${i + 1}' : '',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: AppText.mono(
                      size: 10,
                      weight: FontWeight.w400,
                      color: AppColors.ink2,
                      letterSpacing: 0,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarSlot extends StatelessWidget {
  const _BarSlot({
    super.key,
    required this.band,
    required this.height,
    required this.color,
    required this.semanticLabel,
    required this.onTap,
  });

  final bool band;
  final double height;
  final Color color;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: semanticLabel,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        color: band ? AppColors.paper : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 1),
        alignment: Alignment.bottomCenter,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
        ),
      ),
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      maxLines: 1,
      softWrap: false,
      style: AppText.mono(
        size: 10.5,
        weight: FontWeight.w500,
        color: AppColors.paper,
        letterSpacing: 0,
      ),
    ),
  );
}

/// Menaruh gelembung di tengah batang, 6 px di atasnya, dan menjaganya tetap
/// di dalam lebar grafik.
class _BubbleLayout extends SingleChildLayoutDelegate {
  const _BubbleLayout({required this.centerX, required this.barTop});

  final double centerX;
  final double barTop;

  // Tanpa ini gelembung ikut memenuhi seluruh grafik (batasnya ketat).
  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final maxLeft = size.width - childSize.width;
    final left = (centerX - childSize.width / 2).clamp(
      0.0,
      maxLeft < 0 ? 0.0 : maxLeft,
    );
    return Offset(left, barTop - childSize.height - 6);
  }

  @override
  bool shouldRelayout(_BubbleLayout old) =>
      old.centerX != centerX || old.barTop != barTop;
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.ink2.withValues(alpha: 0.7)
      ..strokeWidth = 1.5;
    const dash = 5.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset((x + dash).clamp(0, size.width), 0),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) => false;
}
