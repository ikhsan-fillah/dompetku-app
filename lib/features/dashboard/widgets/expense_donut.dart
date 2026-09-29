import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/utils/formatter.dart';
import '../models/expense_slice.dart';

class ExpenseDonut extends StatelessWidget {
  const ExpenseDonut({super.key, required this.slices});
  final List<ExpenseSlice> slices;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return const Center(child: Text('Belum ada pengeluaran pada periode ini.'));
    }
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.amount);
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(builder: (context, constraints) {
      final diameter = math.min(196.0, math.max(136.0, constraints.maxWidth - 32));
      return Column(
        children: [
          SizedBox(
            width: diameter, height: diameter,
            child: Stack(fit: StackFit.expand, children: [
              CustomPaint(painter: _DonutPainter(slices, scheme.surfaceContainerHighest)),
              Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Pengeluaran'),
                FittedBox(fit: BoxFit.scaleDown, child: Text(formatIdr(total), style: Theme.of(context).textTheme.titleLarge)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          for (final slice in slices) ...[
            Semantics(
              label: '${slice.name}, ${slice.percent.toStringAsFixed(1)} persen, ${formatIdr(slice.amount)}',
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Container(width: 12, height: 12, decoration: BoxDecoration(color: Color(slice.colorValue), borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(slice.name, maxLines: 2, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${slice.percent.toStringAsFixed(1)}%', style: Theme.of(context).textTheme.titleMedium),
                    Text(formatIdr(slice.amount), style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ]),
              ),
            ),
          ],
        ],
      );
    });
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices, this.background);
  final List<ExpenseSlice> slices;
  final Color background;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<int>(0, (sum, slice) => sum + slice.amount);
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: size.shortestSide / 2 - 13);
    final brush = Paint()..style = PaintingStyle.stroke..strokeWidth = 20;
    canvas.drawArc(rect, 0, math.pi * 2, false, brush..color = background);
    if (total == 0) return;
    var start = -math.pi / 2;
    for (final slice in slices) {
      final sweep = (slice.amount / total) * math.pi * 2;
      canvas.drawArc(rect, start, sweep, false, brush..color = Color(slice.colorValue));
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.slices != slices || oldDelegate.background != background;
}
