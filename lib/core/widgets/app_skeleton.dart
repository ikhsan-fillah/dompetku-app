import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Kerangka berkilau pengganti indikator putar saat data dimuat. Satu
/// [AnimationController] untuk semua kotak di dalamnya (lewat
/// [_ShimmerScope]), dan diam bila HP meminta gerak dikurangi.
class SkeletonShimmer extends StatefulWidget {
  const SkeletonShimmer({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Memuat'.tr,
    child: ExcludeSemantics(
      child: _ShimmerScope(animation: _controller, child: widget.child),
    ),
  );
}

class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({required this.animation, required super.child});

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_ShimmerScope old) => old.animation != animation;
}

/// Satu kotak kerangka. Di luar [SkeletonShimmer] tampil diam.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.radius = 6,
    this.onDark = false,
  });

  final double? width;
  final double height;
  final double radius;

  /// Untuk kotak di atas blok tinta (kartu saldo).
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final animation = context
        .dependOnInheritedWidgetOfExactType<_ShimmerScope>()
        ?.animation;
    final base = onDark
        ? AppColors.paper.withValues(alpha: 0.16)
        : AppColors.paper2;
    final shine = onDark
        ? AppColors.paper.withValues(alpha: 0.28)
        : const Color(0xFFF6F1E6);
    Widget box(double t) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1 + 3 * t - 1, 0),
          end: Alignment(-1 + 3 * t, 0),
          colors: [base, shine, base],
        ),
      ),
    );
    if (animation == null) return box(0);
    return AnimatedBuilder(
      animation: animation,
      builder: (_, _) => box(animation.value),
    );
  }
}

/// Kerangka Beranda: kartu saldo, kartu donat, dan beberapa baris.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(AppRadius.hero),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 110, height: 10, onDark: true),
                SizedBox(height: 10),
                SkeletonBox(width: 190, height: 30, radius: 8, onDark: true),
                SizedBox(height: 20),
                Row(
                  children: [
                    SkeletonBox(width: 100, height: 26, onDark: true),
                    SizedBox(width: 30),
                    SkeletonBox(width: 100, height: 26, onDark: true),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gap),
          const _SkeletonCard(
            child: Row(
              children: [
                SkeletonBox(width: 112, height: 112, radius: 56),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      SkeletonBox(height: 10),
                      SizedBox(height: 10),
                      FractionallySizedBox(
                        widthFactor: 0.8,
                        child: SkeletonBox(height: 10),
                      ),
                      SizedBox(height: 10),
                      FractionallySizedBox(
                        widthFactor: 0.6,
                        child: SkeletonBox(height: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gap),
          const _SkeletonCard(child: _SkeletonRows(count: 3)),
        ],
      ),
    );
  }
}

/// Kerangka daftar (Transaksi, Anggaran, Laporan, detail kategori).
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.rows = 5, this.padding});

  final int rows;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding:
            padding ??
            const EdgeInsets.fromLTRB(AppSpacing.page, 4, AppSpacing.page, 0),
        children: [
          const _SkeletonCard(
            child: Row(
              children: [
                Expanded(child: SkeletonBox(height: 34)),
                SizedBox(width: 16),
                Expanded(child: SkeletonBox(height: 34)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.gap),
          _SkeletonCard(child: _SkeletonRows(count: rows)),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.card),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.card),
      border: Border.all(color: AppColors.line),
    ),
    child: child,
  );
}

class _SkeletonRows extends StatelessWidget {
  const _SkeletonRows({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < count; i++) ...[
        if (i > 0) const SizedBox(height: 14),
        Row(
          children: [
            const SkeletonBox(width: 36, height: 36, radius: 10),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: i.isEven ? 0.6 : 0.45,
                    child: const SkeletonBox(height: 10),
                  ),
                  const SizedBox(height: 6),
                  const FractionallySizedBox(
                    widthFactor: 0.35,
                    child: SkeletonBox(height: 8),
                  ),
                ],
              ),
            ),
            const SkeletonBox(width: 64, height: 12),
          ],
        ),
      ],
    ],
  );
}
