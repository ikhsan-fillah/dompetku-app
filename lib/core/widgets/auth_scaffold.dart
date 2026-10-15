import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
    this.kicker,
    this.step,
    this.hero,
    this.dark = true,
    this.sheet = true,
    this.failed = false,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget child;
  final String? kicker;
  final String? step;
  final Widget? hero;
  final bool dark;
  final bool sheet;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final heroWidget = hero ?? AuthOrb(icon: icon, dark: dark, failed: failed);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: dark ? AppColors.ink : AppColors.paper,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (kicker != null)
                _Rule(kicker: kicker!, step: step, dark: dark),
              Expanded(
                child: sheet
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                ),
                                child: heroWidget,
                              ),
                            ),
                          ),
                          _sheet(),
                        ],
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(child: heroWidget),
                            const SizedBox(height: 28),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: AppText.display(size: 26),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              textAlign: TextAlign.center,
                              style: AppText.body(
                                size: 13,
                                color: AppColors.mut,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            child,
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheet() => Container(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadius.hero),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppText.display(size: 24, height: 1.15)),
        const SizedBox(height: 10),
        Text(
          description,
          style: AppText.body(size: 12, color: AppColors.ink2, height: 1.5),
        ),
        const SizedBox(height: 20),
        child,
      ],
    ),
  );
}

class _Rule extends StatelessWidget {
  const _Rule({required this.kicker, this.step, required this.dark});

  final String kicker;
  final String? step;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = dark ? AppColors.paper.withValues(alpha: 0.7) : AppColors.mut;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(kicker, style: AppText.monoLabel(color: color, size: 11)),
          if (step != null)
            Text(step!, style: AppText.monoLabel(color: color, size: 11)),
        ],
      ),
    );
  }
}

class AuthOrb extends StatelessWidget {
  const AuthOrb({
    super.key,
    required this.icon,
    this.dark = true,
    this.failed = false,
  });

  final IconData icon;
  final bool dark;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final Color disc;
    final Color glyph;
    final Color ring;
    if (failed) {
      disc = AppColors.spend;
      glyph = Colors.white;
      ring = AppColors.spendSoft;
    } else if (dark) {
      disc = AppColors.paper;
      glyph = AppColors.ink;
      ring = AppColors.paper.withValues(alpha: 0.12);
    } else {
      disc = AppColors.ink;
      glyph = AppColors.paper;
      ring = AppColors.paper2;
    }
    return Container(
      width: 124,
      height: 124,
      decoration: BoxDecoration(color: ring, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(color: disc, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(icon, size: 52, color: glyph),
      ),
    );
  }
}
