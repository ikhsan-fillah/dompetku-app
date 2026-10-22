import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/services/app_version.dart';
import '../controllers/splash_controller.dart';

/// Layar pembuka Tally. Menentukan halaman berikutnya lewat SplashController.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
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
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paper = AppColors.paper;
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: paper.withValues(alpha: 0.2)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PENCATAT KEUANGAN'.tr,
                      style: AppText.monoLabel(
                        color: paper.withValues(alpha: 0.7),
                      ),
                    ),
                    Text(
                      'v@version'.trParams({'version': AppVersion.name}),
                      style: AppText.monoLabel(
                        color: paper.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
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
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            color: paper,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            LucideIcons.wallet,
                            size: 40,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Tal'),
                              TextSpan(
                                text: 'ly',
                                style: AppText.display(
                                  size: 40,
                                  weight: FontWeight.w300,
                                  fontStyle: FontStyle.italic,
                                  color: paper,
                                ),
                              ),
                            ],
                          ),
                          style: AppText.display(size: 40, color: paper),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Uangmu, catatanmu, tetap di ponselmu.'.tr,
                          textAlign: TextAlign.center,
                          style: AppText.body(
                            size: 13,
                            color: paper.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Semantics(
                          label: 'Menyiapkan Tally'.tr,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Menyiapkan Tally'.tr,
                                style: AppText.monoLabel(
                                  color: paper.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _Loader(animation: _loader),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Loader extends StatelessWidget {
  const _Loader({required this.animation});

  final Animation<double> animation;

  static const double _width = 120;
  static const double _segment = 48;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: 2,
      child: ClipRect(
        child: Stack(
          children: [
            Container(
              width: _width,
              height: 2,
              color: AppColors.paper.withValues(alpha: 0.2),
            ),
            AnimatedBuilder(
              animation: animation,
              builder: (context, child) => Transform.translate(
                offset: Offset(
                  -_segment + (_width + _segment) * animation.value,
                  0,
                ),
                child: child,
              ),
              child: Container(
                width: _segment,
                height: 2,
                color: AppColors.paper,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
