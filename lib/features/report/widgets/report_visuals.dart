import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/i18n/app_language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../controllers/report_controller.dart';
import '../../../core/widgets/motion.dart';

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

/// Cincin pengeluaran per kategori. Ketuk potongan untuk melihat nama,
/// nominal, dan persen kategorinya di tengah (sama seperti donat Beranda);
/// ketuk lagi untuk kembali ke total.
class SpendingRing extends StatefulWidget {
  const SpendingRing({
    super.key,
    required this.items,
    required this.total,
    required this.totalLabel,
    this.money,
  });

  final List<ReportCategoryTotal> items;
  final int total;
  final String totalLabel;

  /// Format nominal kategori terpilih; bawaan memakai [totalLabel] saja.
  final String Function(int)? money;

  @override
  State<SpendingRing> createState() => _SpendingRingState();
}

class _SpendingRingState extends State<SpendingRing> {
  int? _selected;

  @override
  void didUpdateWidget(SpendingRing old) {
    super.didUpdateWidget(old);
    if (old.items != widget.items) _selected = null;
  }

  /// Potongan pada titik [position] (relatif ke kotak berukuran [side]).
  int? _sliceAt(Offset position, double side) {
    if (widget.total <= 0) return null;
    final stroke = side * _RingPainter.strokeFactor;
    final radius = (side - stroke) / 2;
    final delta = position - Offset(side / 2, side / 2);
    final distance = delta.distance;
    // Area ketuk sedikit lebih lebar dari cincinnya.
    if (distance < radius - stroke || distance > side / 2 + 6) return null;
    var angle = math.atan2(delta.dy, delta.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    var start = 0.0;
    for (var i = 0; i < widget.items.length; i++) {
      final sweep = widget.items[i].amount / widget.total * 2 * math.pi;
      if (angle >= start && angle < start + sweep) return i;
      start += sweep;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 1.35,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxHeight, constraints.maxWidth);
        final selected = _selected != null && _selected! < widget.items.length
            ? _selected
            : null;
        final item = selected == null ? null : widget.items[selected];
        final percent = item == null || widget.total <= 0
            ? 0
            : (item.amount * 100 / widget.total).round();
        return Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final index = _sliceAt(details.localPosition, side);
              if (index == null) return;
              setState(() => _selected = _selected == index ? null : index);
            },
            child: SizedBox.square(
              dimension: side,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size.square(side),
                    painter: _RingPainter(widget.items, widget.total, selected),
                  ),
                  IgnorePointer(
                    child: Padding(
                      padding: EdgeInsets.all(side * 0.2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item?.name ?? 'Total pengeluaran'.tr,
                              style: AppText.body(
                                size: 11,
                                color: AppColors.mut,
                              ),
                            ),
                            const SizedBox(height: 2),
                            RollingText(
                              item == null
                                  ? widget.totalLabel
                                  : (widget.money?.call(item.amount) ??
                                        '${item.amount}'),
                              style: AppText.mono(
                                size: 22,
                                weight: FontWeight.w600,
                                letterSpacing: -0.4,
                                color: item == null
                                    ? AppColors.ink
                                    : Color(item.colorValue),
                              ),
                            ),
                            if (item != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                '$percent%',
                                style: AppText.mono(
                                  size: 12,
                                  color: AppColors.ink2,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.items, this.total, this.selected);

  static const strokeFactor = 0.13;

  final List<ReportCategoryTotal> items;
  final int total;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * strokeFactor;
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
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final sweep = item.amount / total * math.pi * 2;
      if (sweep <= 0) continue;
      final isSelected = selected == i;
      final color = Color(item.colorValue);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? stroke * 1.25 : stroke
        ..strokeCap = StrokeCap.butt
        ..color = selected == null || isSelected
            ? color
            : color.withValues(alpha: 0.3);
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
      old.total != total || old.items != items || old.selected != selected;
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
          RollingText(
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
