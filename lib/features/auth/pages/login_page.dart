import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool busy = false;
  String? error;

  Future<void> start() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final auth = Get.find<AuthController>();
      await auth.markRegistered();
      if (mounted) Get.offAllNamed(AppRoutes.biometricSetup);
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error = 'Gagal menyiapkan aplikasi. Coba lagi.'.tr;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AuthScaffold(
    icon: LucideIcons.wallet,
    kicker: 'MULAI'.tr,
    step: '01 / 02',
    title: 'Mulai kelola uangmu'.tr,
    description:
        'Tally mencatat pemasukan dan pengeluaran secara pribadi di perangkat ini. Tidak perlu akun atau koneksi internet.'
            .tr,
    hero: const _SampleLedger(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FeatureRow(
          icon: LucideIcons.shieldCheck,
          text: 'Dibuka dengan sidik jari / wajah'.tr,
        ),
        const SizedBox(height: 10),
        _FeatureRow(
          icon: LucideIcons.lock,
          text: 'Tanpa akun, tanpa cloud, tanpa iklan'.tr,
        ),
        const SizedBox(height: 10),
        _FeatureRow(
          icon: LucideIcons.camera,
          text: 'Scan struk, lalu kamu yang memutuskan'.tr,
        ),
        const SizedBox(height: 20),
        if (error != null) ...[
          Text(error!, style: AppText.body(size: 12, color: AppColors.spend)),
          const SizedBox(height: 12),
        ],
        AppButton(
          onPressed: busy ? null : start,
          label: busy
              ? 'Menyiapkan...'.tr
              : 'Mulai & pasang kunci biometrik'.tr,
        ),
      ],
    ),
  );
}

class _SampleLedger extends StatelessWidget {
  const _SampleLedger();

  static List<(String, String)> get _rows => [
    ('Gaji September'.tr, '+5.000.000'),
    ('Listrik PLN'.tr, '\u2212438.000'),
    ('Warung Sederhana'.tr, '\u221245.000'),
    ('Gojek', '\u221232.000'),
  ];

  @override
  Widget build(BuildContext context) {
    final faint = AppColors.paper.withValues(alpha: 0.14);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'CONTOH TAMPILAN DATA'.tr,
            style: AppText.monoLabel(
              color: AppColors.paper.withValues(alpha: 0.6),
              size: 11,
            ),
          ),
          const SizedBox(height: 14),
          for (final row in _rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: faint)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: AppColors.paper,
                      ),
                    ),
                  ),
                  Text(
                    row.$2,
                    style: AppText.mono(
                      size: 13,
                      weight: FontWeight.w400,
                      color: AppColors.paper.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'Sisa'.tr,
                style: AppText.body(
                  size: 13,
                  color: AppColors.paper.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              Text(
                'Rp 4.485.000',
                style: AppText.display(size: 26, color: AppColors.paper),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.paper2,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: AppColors.ink),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: AppText.body(size: 12.5, color: AppColors.ink2),
        ),
      ),
    ],
  );
}
