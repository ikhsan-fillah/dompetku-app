import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

const recapMonthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

const recapMonthShort = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Tally: setiap lima goresan = empat tegak dan satu coret miring.
class TallyMarks extends StatelessWidget {
  const TallyMarks({
    super.key,
    required this.count,
    this.color = AppColors.ink,
    this.height = 22,
  });

  final int count;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final spacing = height * 0.42;
    final groups = (count + 4) ~/ 5;
    return Wrap(
      spacing: spacing,
      runSpacing: 6,
      children: [
        for (var g = 0; g < groups; g++)
          CustomPaint(
            size: Size(spacing * 5, height),
            painter: _TallyGroupPainter(
              strokes: (count - g * 5).clamp(0, 5),
              color: color,
              spacing: spacing,
            ),
          ),
      ],
    );
  }
}

class _TallyGroupPainter extends CustomPainter {
  _TallyGroupPainter({
    required this.strokes,
    required this.color,
    required this.spacing,
  });

  final int strokes;
  final Color color;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    final top = size.height * 0.1;
    final bottom = size.height * 0.9;
    final verticals = strokes == 5 ? 4 : strokes;
    for (var i = 0; i < verticals; i++) {
      final x = spacing * 0.5 + i * spacing;
      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
    if (strokes == 5) {
      canvas.drawLine(
        Offset(spacing * 0.2, bottom - size.height * 0.2),
        Offset(spacing * 3.8, top + size.height * 0.2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_TallyGroupPainter old) =>
      old.strokes != strokes || old.color != color || old.spacing != spacing;
}

/// Kotak dengan border putus-putus (hari tanpa pengeluaran, bulan tanpa data).
class DashedBox extends StatelessWidget {
  const DashedBox({
    super.key,
    required this.child,
    this.color = AppColors.line,
    this.radius = 6,
  });

  final Widget child;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _DashedPainter(color: color, radius: radius),
      child: child,
    );
  }
}

class _DashedPainter extends CustomPainter {
  _DashedPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + 4).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 7;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter old) =>
      old.color != color || old.radius != radius;
}

/// Angka yang naik dari nol ke [value] (count-up).
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    required this.style,
  });

  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        final amount = v.round();
        final sign = amount < 0 ? '-' : '';
        return Text(
          '${sign}Rp ${_group(amount.abs())}',
          style: style,
        );
      },
    );
  }

  static String _group(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

/// Stempel status anggaran (SAFE, WATCH, CRITICAL, OVER).
class BudgetStamp extends StatelessWidget {
  const BudgetStamp({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppText.label(color: color, size: 10),
      ),
    );
  }
}

/// Judul kecil di atas setiap kartu.
class StoryLabel extends StatelessWidget {
  const StoryLabel(this.text, {super.key, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppText.label(color: color, size: 11));
  }
}
