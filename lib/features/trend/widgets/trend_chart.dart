import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/formatter.dart';
import '../models/monthly_trend.dart';
import '../../../core/widgets/motion.dart';

/// Baris total di bawah grafik: "Total · 22 dari 31 hari" dan nominalnya.
class TrendTotalLine extends StatelessWidget {
  const TrendTotalLine({super.key, required this.trend});

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
        RollingText(
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
/// terpilih. Dipakai kartu tren pengeluaran dan pemasukan di Laporan.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.trend,
    required this.selected,
    required this.onTapDay,
    this.accent = AppColors.ink,
    this.peakColor = AppColors.spend,
    this.showAverage = true,
  });

  final MonthlyTrend trend;
  final int? selected;
  final ValueChanged<int> onTapDay;

  /// Warna dasar batang biasa; bawaan tinta untuk pengeluaran.
  final Color accent;

  /// Warna batang tertinggi.
  final Color peakColor;

  /// Menampilkan garis putus-putus rata-rata per hari.
  final bool showAverage;

  static const chartHeight = 120.0;
  static const _bubbleRoom = 34.0;

  Color _barColor(int index, int? peakIndex) {
    if (index >= trend.elapsedDays) return AppColors.line2;
    if (trend.daily[index] == 0) return AppColors.line;
    if (index == selected) return AppColors.ink;
    if (index == peakIndex) return peakColor;
    if (trend.isCurrent && index == trend.elapsedDays - 1) {
      return accent == AppColors.ink
          ? AppColors.ink2
          : accent.withValues(alpha: 0.65);
    }
    return accent.withValues(alpha: 0.32);
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
                  if (showAverage && trend.peakAmount > 0 && average > 0)
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
