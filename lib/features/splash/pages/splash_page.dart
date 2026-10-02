import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/splash_controller.dart';

/// Layar pembuka DompetKu. Menentukan halaman berikutnya lewat SplashController.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _dots;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    final controller = Get.isRegistered<SplashController>()
        ? Get.find<SplashController>()
        : Get.put(SplashController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.decideNextPage();
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F766E), Color(0xFF10B981)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOut,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 16),
                    child: child,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PulseWallet(animation: _pulse),
                    const SizedBox(height: 12),
                    const Text(
                      'DompetKu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Catat uang, tenangkan pikiran',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Semantics(
                      label: 'Menyiapkan DompetKu',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Menyiapkan DompetKu',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _LoadingDots(animation: _dots),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ikon dompet dengan dua lingkaran transparan yang "bernapas" di belakangnya.
class _PulseWallet extends StatelessWidget {
  const _PulseWallet({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final t = Curves.easeInOut.transform(animation.value);
          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.scale(
                scale: 1.0 + 0.15 * t,
                child: _Disc(size: 150, alpha: 0.12 - 0.06 * t),
              ),
              Transform.scale(
                scale: 1.0 + 0.10 * t,
                child: _Disc(size: 122, alpha: 0.10 + 0.06 * t),
              ),
              child!,
            ],
          );
        },
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            size: 48,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

/// Tiga titik yang menyala bergantian (tanpa spinner dan tanpa garis progres).
class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.animation});

  final Animation<double> animation;

  double _intensity(int index) {
    final phase = (animation.value * 3 - index) % 3;
    return phase < 1 ? math.sin(phase * math.pi) : 0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              _dot(_intensity(i)),
            ],
          ],
        );
      },
    );
  }

  Widget _dot(double intensity) {
    return SizedBox(
      width: 12,
      height: 12,
      child: Center(
        child: Container(
          width: 6 + 4 * intensity,
          height: 6 + 4 * intensity,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.4 + 0.6 * intensity),
          ),
        ),
      ),
    );
  }
}
