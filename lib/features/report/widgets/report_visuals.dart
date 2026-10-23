import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../controllers/report_controller.dart';

/// Pemilih bulan: panah kiri/kanan dengan nama bulan di tengah.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.canGoNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;
  final bool canGoNext;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
    child: Row(
      children: [
        _ArrowButton(
          icon: LucideIcons.chevronLeft,
          onTap: onPrevious,
          label: 'Bulan sebelumnya'.tr,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                AppLanguage.monthLong(month.month),
                style: AppText.display(size: 28, weight: FontWeight.w600),
              ),
              Text(
                '${month.year}',
                style: AppText.mono(
                  size: 12,
                  weight: FontWeight.w500,
                  color: AppColors.mut,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
        _ArrowButton(
          icon: LucideIcons.chevronRight,
          onTap: canGoNext ? onNext : null,
          label: 'Bulan berikutnya'.tr,
        ),
      ],
    ),
  );
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.onTap,
    required this.label,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: InkResponse(
      onTap: onTap,
      radius: 26,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.paper : AppColors.paper2,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: onTap == null ? AppColors.line : AppColors.ink,
        ),
      ),
    ),
  );
}

/// Cincin pengeluaran per kategori dengan total di tengah.
class SpendingRing extends StatelessWidget {
  const SpendingRing({
    super.key,
    required this.items,
    required this.total,
    required this.totalLabel,
  });

  final List<ReportCategoryTotal> items;
  final int total;
  final String totalLabel;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.35,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxHeight, constraints.maxWidth);
        return Center(
          child: SizedBox.square(
            dimension: side,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.square(side),
                  painter: _RingPainter(items, total),
                ),
                Padding(
                  padding: EdgeInsets.all(side * 0.2),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Total pengeluaran'.tr,
                          style: AppText.body(size: 11, color: AppColors.mut),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          totalLabel,
                          style: AppText.mono(
                            size: 22,
                            weight: FontWeight.w600,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.items, this.total);

  final List<ReportCategoryTotal> items;
  final int total;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.13;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.paper2;
    canvas.drawArc(rect, 0, math.pi * 2, false, track);
    if (total <= 0) return;

    const gap = 0.035;
    var start = -math.pi / 2;
    for (final item in items) {
      final sweep = item.amount / total * math.pi * 2;
      if (sweep <= 0) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt
        ..color = Color(item.colorValue);
      final visible = items.length > 1 && sweep > gap * 2 ? sweep - gap : sweep;
      canvas.drawArc(
        rect,
        start + (sweep - visible) / 2,
        visible,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.total != total || old.items != items;
}

/// Pemasukan dan pengeluaran sebagai dua batang sejajar, plus selisihnya.
class IncomeExpenseBars extends StatelessWidget {
  const IncomeExpenseBars({
    super.key,
    required this.income,
    required this.expense,
    required this.money,
  });

  final int income;
  final int expense;
  final String Function(int) money;

  @override
  Widget build(BuildContext context) {
    final peak = math.max(math.max(income, expense), 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FlowRow(
          label: 'Pemasukan'.tr,
          value: money(income),
          fraction: income / peak,
          color: AppColors.earn,
          track: AppColors.earnSoft,
        ),
        const SizedBox(height: 12),
        _FlowRow(
          label: 'Pengeluaran'.tr,
          value: money(expense),
          fraction: expense / peak,
          color: AppColors.spend,
          track: AppColors.spendSoft,
        ),
        const SizedBox(height: 14),
        const Divider(height: 1, thickness: 1, color: AppColors.line2),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Selisih bulan ini'.tr,
                style: AppText.body(size: 12, weight: FontWeight.w700),
              ),
            ),
            Text(
              money(income - expense),
              style: AppText.mono(
                size: 14,
                weight: FontWeight.w600,
                color: income >= expense ? AppColors.earn : AppColors.spend,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FlowRow extends StatelessWidget {
  const _FlowRow({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
    required this.track,
  });

  final String label;
  final String value;
  final double fraction;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppText.body(size: 11.5, color: AppColors.mut),
            ),
          ),
          Text(
            value,
            style: AppText.mono(
              size: 12.5,
              weight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 10,
          color: track,
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (_, factor, _) => FractionallySizedBox(
              widthFactor: factor,
              child: ColoredBox(color: color),
            ),
          ),
        ),
      ),
    ],
  );
}
