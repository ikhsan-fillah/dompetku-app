import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

/// Batang progres: tinggi 6, ujung membulat, track `paper2`. Animasi 400 ms.
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
      value: '@percent persen'.trParams({
        'percent': '${(target * 100).round()}',
      }),
      child: Container(
        height: height,
        alignment: Alignment.centerLeft,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: trackColor,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: target),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, factor, _) => FractionallySizedBox(
            widthFactor: factor,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height / 2),
              ),
              child: SizedBox(height: height),
            ),
          ),
        ),
      ),
    );
  }
}
