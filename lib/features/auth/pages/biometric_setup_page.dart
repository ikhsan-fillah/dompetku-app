import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constant/domain_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../controllers/auth_controller.dart';

/// Halaman Setup Biometrik sesuai mockup 3:
/// - Background dark ink
/// - KUNCI 02 / 02 di atas
/// - Ikon sidik jari di lingkaran paper di tengah
/// - Bottom sheet: Pasang kunci dulu.
/// - Teks privasi menegaskan app tidak menyimpan data sidik jari
/// - Tombol Verifikasi biometrik & Pakai PIN
/// - Biometrik baru dianggap aktif setelah verifikasi berhasil
class BiometricSetupPage extends StatelessWidget {
  const BiometricSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar: KUNCI & 02 / 02
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'KUNCI',
                    style: AppText.monoLabel(
                      color: AppColors.paper.withValues(alpha: 0.7),
                      size: 11,
                    ),
                  ),
                  Text(
                    '02 / 02',
                    style: AppText.monoLabel(
                      color: AppColors.paper.withValues(alpha: 0.7),
                      size: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Hero Circle in Center
            Expanded(
              child: Center(
                child: Container(
                  width: 124,
                  height: 124,
                  decoration: BoxDecoration(
                    color: const Color(0xFF283632),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: const BoxDecoration(
                      color: AppColors.paper,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.fingerprint,
                      size: 52,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Obx(() {
                final status = auth.biometricStatus.value;
                final busy = status == BiometricStatus.authenticating;
                final failed = status == BiometricStatus.failed;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Pasang kunci dulu.',
                      style: AppText.display(size: 24, height: 1.15),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Verifikasi biometrik sekali. Angka tidak akan tampil sebelum kamu lolos. Tally tidak menyimpan data sidik jari/wajah — itu urusan sistem operasi.',
                      style: AppText.body(
                        size: 12,
                        color: AppColors.ink2,
                        height: 1.5,
                      ),
                    ),
                    if (failed) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Verifikasi gagal. Silakan coba lagi.',
                        style: AppText.body(
                          size: 12,
                          color: AppColors.spend,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Button 1: Verifikasi biometrik
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: busy
                            ? null
                            : () async {
                                final success = await auth.setupBiometric();
                                if (success && context.mounted) {
                                  Get.offAllNamed(AppRoutes.home);
                                }
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: AppColors.paper,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.fingerprint,
                              size: 18,
                              color: AppColors.paper,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              busy ? 'Memverifikasi...' : 'Verifikasi biometrik',
                              style: AppText.body(
                                size: 14,
                                weight: FontWeight.w700,
                                color: AppColors.paper,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Button 2: Pakai PIN
                    SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: busy
                            ? null
                            : () async {
                                // Biometrik tidak diaktifkan bila memilih PIN
                                await auth.setBiometricEnabled(false);
                                if (context.mounted) {
                                  Get.offAllNamed(AppRoutes.pinCreate);
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.ink,
                          side: const BorderSide(color: AppColors.ink, width: 1.2),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Perangkat tanpa biometrik? Pakai PIN',
                          style: AppText.body(
                            size: 13,
                            weight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
