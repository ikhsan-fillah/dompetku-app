import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// Geometri yang dipakai bersama semua panel chart, supaya garis penunjuk
/// hari jatuh di posisi yang sama di setiap panel.
class ChartFrame {
  const ChartFrame(this.size, this.count, {this.bottomPad = 4});

  /// Lebar sumbu harga di kanan.
  static const axisWidth = 52.0;
  static const topPad = 8.0;

  final Size size;
  final int count;
  final double bottomPad;

  Rect get plot => Rect.fromLTRB(
    0,
    topPad,
    math.max(1, size.width - axisWidth),
    math.max(topPad + 1, size.height - bottomPad),
  );

  double get step => count == 0 ? plot.width : plot.width / count;

  double xOf(int index) => plot.left + (index + 0.5) * step;

  /// Posisi vertikal nilai [v] pada rentang [lo]..[hi] (hi di atas).
  double yOf(double v, double lo, double hi) {
    if (hi <= lo) return plot.center.dy;
    return plot.bottom - (v - lo) / (hi - lo) * plot.height;
  }

  /// Indeks hari terdekat dari posisi sentuh [dx] pada lebar [width].
  static int indexAt(double dx, double width, int count) {
    if (count <= 1) return 0;
    final plotWidth = math.max(1.0, width - axisWidth);
    return (dx / plotWidth * count).floor().clamp(0, count - 1);
  }
}

/// Menulis teks di [at]; [anchor] menentukan sudut teks yang menempel di titik.
void paintText(
  Canvas canvas,
  String text,
  Offset at, {
  TextStyle? style,
  Alignment anchor = Alignment.centerLeft,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style:
          style ??
          AppText.mono(size: 10, color: AppColors.mut, letterSpacing: -0.2),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  painter.paint(
    canvas,
    at -
        Offset(
          painter.width * (anchor.x + 1) / 2,
          painter.height * (anchor.y + 1) / 2,
        ),
  );
}

/// Garis putus-putus dari [from] ke [to].
void paintDashedLine(
  Canvas canvas,
  Offset from,
  Offset to,
  Paint paint, {
  double dash = 4,
  double gap = 3,
}) {
  final path = Path()
    ..moveTo(from.dx, from.dy)
    ..lineTo(to.dx, to.dy);
  canvas.drawPath(_dashed(path, dash, gap), paint);
}

Path _dashed(Path source, double dash, double gap) {
  final result = Path();
  for (final metric in source.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final end = math.min(distance + dash, metric.length);
      result.addPath(metric.extractPath(distance, end), Offset.zero);
      distance += dash + gap;
    }
  }
  return result;
}

/// Menggambar deret nilai sebagai garis. Titik kosong memutus garis, bukan
/// disambung, supaya data yang hilang tidak tampak seperti data.
void paintSeries(
  Canvas canvas,
  ChartFrame frame,
  List<double?> values,
  double lo,
  double hi,
  Paint paint, {
  bool dashed = false,
}) {
  final path = Path();
  var open = false;
  for (var i = 0; i < values.length; i++) {
    final value = values[i];
    if (value == null) {
      open = false;
      continue;
    }
    final point = Offset(frame.xOf(i), frame.yOf(value, lo, hi));
    if (open) {
      path.lineTo(point.dx, point.dy);
    } else {
      path.moveTo(point.dx, point.dy);
      open = true;
      // Satu titik sendirian tetap terlihat sebagai titik kecil.
      canvas.drawCircle(point, 1.2, Paint()..color = paint.color);
    }
  }
  canvas.drawPath(dashed ? _dashed(path, 5, 3) : path, paint);
}

/// Garis tegak penunjuk hari terpilih.
void paintCrosshair(Canvas canvas, ChartFrame frame, int? selected) {
  if (selected == null || selected < 0 || selected >= frame.count) return;
  final x = frame.xOf(selected);
  canvas.drawLine(
    Offset(x, frame.plot.top),
    Offset(x, frame.plot.bottom),
    Paint()
      ..color = AppColors.ink.withValues(alpha: 0.35)
      ..strokeWidth = 1,
  );
}

/// Garis bantu mendatar dengan label di sumbu kanan.
void paintGridLine(
  Canvas canvas,
  ChartFrame frame,
  double y,
  String label, {
  bool dashed = false,
}) {
  final paint = Paint()
    ..color = AppColors.line
    ..strokeWidth = 1;
  final from = Offset(frame.plot.left, y);
  final to = Offset(frame.plot.right, y);
  if (dashed) {
    paintDashedLine(canvas, from, to, paint);
  } else {
    canvas.drawLine(from, to, paint..color = AppColors.line2);
  }
  paintText(canvas, label, Offset(frame.plot.right + 6, y));
}

/// Label tanggal di bawah panel: awal dan akhir rentang.
void paintDateAxis(Canvas canvas, ChartFrame frame, String first, String last) {
  final y = frame.size.height - 6;
  paintText(
    canvas,
    first,
    Offset(frame.plot.left, y),
    anchor: Alignment.centerLeft,
  );
  paintText(
    canvas,
    last,
    Offset(frame.plot.right, y),
    anchor: Alignment.centerRight,
  );
}

/// Warna garis kedua: sama dengan aksen app dan putus-putus, supaya dua garis
/// tetap terbedakan tanpa bergantung pada warna.
Paint linePaint(Color color, {double width = 1.6}) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round
  ..isAntiAlias = true;

/// Kotak kecil berisi nilai terakhir di sumbu kanan.
void paintValueTag(Canvas canvas, ChartFrame frame, double y, String text) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: AppText.mono(
        size: 10,
        color: AppColors.paper,
        weight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  final rect = Rect.fromLTWH(
    frame.plot.right + 2,
    y - painter.height / 2 - 2,
    painter.width + 8,
    painter.height + 4,
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, const Radius.circular(3)),
    Paint()..color = AppColors.ink,
  );
  painter.paint(canvas, Offset(rect.left + 4, rect.top + 2));
}

/// Bentuk pendek untuk menyalin warna dengan alfa.
Color fade(Color color, double alpha) => color.withValues(alpha: alpha);
