import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Batang progres dengan animasi. [value] bernilai 0.0 sampai 1.0.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.gradient = AppColors.primaryGradient,
    this.height = 9,
  });

  final double value;
  final Gradient gradient;
  final double height;

  @override
  Widget build(BuildContext context) {
    final target = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
    return Semantics(
      value: '${(target * 100).round()} persen',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: Container(
          height: height,
          color: AppColors.track,
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: target),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, factor, _) => FractionallySizedBox(
              widthFactor: factor,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(height),
                ),
                child: SizedBox(height: height),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
