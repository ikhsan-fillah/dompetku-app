import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/category_style.dart';
import '../../../core/utils/formatter.dart';
import '../../../core/utils/percent_rounding.dart';
import '../models/expense_slice.dart';

/// Donat pengeluaran per kategori, urut dari terbesar ke terkecil.
class ExpenseDonut extends StatefulWidget {
  const ExpenseDonut({super.key, required this.slices});

  final List<ExpenseSlice> slices;

  @override
  State<ExpenseDonut> createState() => _ExpenseDonutState();
}

class _ExpenseDonutState extends State<ExpenseDonut> {
  static const double _size = 136;
  static const int _legendLimit = 5;
  int? _selected;

  int get _total => widget.slices.fold<int>(0, (sum, s) => sum + s.amount);

  void _toggle(int index) {
    setState(() => _selected = _selected == index ? null : index);
  }

  int? _sliceAt(Offset position) {
    const center = Offset(_size / 2, _size / 2);
    final delta = position - center;
    final distance = delta.distance;
    if (distance < 38 || distance > _size / 2) return null;
    var angle = math.atan2(delta.dy, delta.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    final total = _total;
    if (total <= 0) return null;
    var start = 0.0;
    for (var i = 0; i < widget.slices.length; i++) {
      final sweep = widget.slices[i].amount / total * 2 * math.pi;
      if (angle >= start && angle < start + sweep) return i;
      start += sweep;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final slices = widget.slices;
    if (slices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text('Belum ada pengeluaran pada periode ini.')),
      );
    }
    final percents = roundPercentages([
      for (final s in slices) s.amount.toDouble(),
    ]);
    final selected = (_selected != null && _selected! < slices.length)
        ? _selected
        : null;

    final donut = GestureDetector(
      onTapUp: (details) {
        final index = _sliceAt(details.localPosition);
        if (index != null) _toggle(index);
      },
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: const Size.square(_size),
              painter: _DonutPainter(slices, selected),
            ),
            IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.all(34),
                child: selected == null
                    ? _CenterText(
                        top: 'Total',
                        amount: _total,
                        color: AppColors.ink,
                      )
                    : _CenterText(
                        top: slices[selected].name,
                        amount: slices[selected].amount,
                        bottom: '${percents[selected]}%',
                        color: CategoryStyle.color(slices[selected].colorValue),
                      ),
              ),
            ),
          ],
        ),
      ),
    );

    final shown = slices.length > _legendLimit ? _legendLimit : slices.length;
    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < shown; i++)
          _LegendRow(
            slice: slices[i],
            percent: percents[i],
            selected: selected == i,
            onTap: () => _toggle(i),
          ),
        if (slices.length > _legendLimit)
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 4),
            child: Text(
              '+${slices.length - _legendLimit} kategori lain',
              style: const TextStyle(fontSize: 10.5, color: AppColors.muted),
            ),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 300) {
          return Column(children: [donut, const SizedBox(height: 16), legend]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            donut,
            const SizedBox(width: 14),
            Expanded(child: legend),
          ],
        );
      },
    );
  }
}

class _CenterText extends StatelessWidget {
  const _CenterText({
    required this.top,
    required this.amount,
    required this.color,
    this.bottom,
  });

  final String top;
  final int amount;
  final String? bottom;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          top,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 9.5, color: AppColors.muted),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            formatIdr(amount),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        if (bottom != null)
          Text(
            bottom!,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.slice,
    required this.percent,
    required this.selected,
    required this.onTap,
  });

  final ExpenseSlice slice;
  final int percent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = CategoryStyle.color(slice.colorValue);
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '${slice.name}, $percent persen, ${formatIdr(slice.amount)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? AppColors.mintSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slice.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5),
                    ),
                    Text(
                      formatIdr(slice.amount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices, this.selected);

  final List<ExpenseSlice> slices;
  final int? selected;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<int>(0, (sum, s) => sum + s.amount);
    if (total <= 0) return;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.shortestSide / 2 - 13,
    );
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..color = AppColors.track,
    );
    const gap = 0.045;
    var start = -math.pi / 2;
    for (var i = 0; i < slices.length; i++) {
      final sweep = slices[i].amount / total * 2 * math.pi;
      final spaced = sweep > gap * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected == i ? 24 : 18
        ..color = CategoryStyle.color(
          slices[i].colorValue,
        ).withValues(alpha: selected == null || selected == i ? 1 : 0.35);
      canvas.drawArc(
        rect,
        start + (spaced ? gap / 2 : 0),
        spaced ? sweep - gap : sweep,
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.selected != selected || oldDelegate.slices != slices;
}
