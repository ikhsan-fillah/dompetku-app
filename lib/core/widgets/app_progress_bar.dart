import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Batang progres (spec §2.3): tinggi 6, radius 0, track `paper2`. Animasi 400 ms.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.ink,
    this.height = 6,
    this.trackColor = AppColors.paper2,
  });

  final double value;
  final Color color;
  final double height;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final target = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
    return Semantics(
      value: '${(target * 100).round()} persen',
      child: Container(
        height: height,
        color: trackColor,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: target),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, factor, _) => FractionallySizedBox(
            widthFactor: factor,
            child: ColoredBox(color: color, child: SizedBox(height: height)),
          ),
        ),
      ),
    );
  }
}
