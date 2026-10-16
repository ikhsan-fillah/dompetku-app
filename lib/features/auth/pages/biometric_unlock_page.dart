import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constant/app_constant.dart';
import '../../../core/constant/domain_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../profile/controllers/profile_controller.dart';
import '../controllers/auth_controller.dart';

/// Halaman Unlock Biometrik & Layar Terkunci sesuai Mockup 4 & 5:
/// - Mockup 4 (Unlock): Avatar inisial IF, "Selamat datang kembali",
///   tombol sidik jari (berubah merah saat gagal), lima titik sisa percobaan,
///   tanpa panel simulasi mockup.
/// - Mockup 5 (Terkunci): "Jeda sebentar.", hitung mundur 5 menit live,
///   "Data keuanganmu tetap tersembunyi", tanpa tombol lewati demo.
class BiometricUnlockPage extends StatelessWidget {
  const BiometricUnlockPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Obx(() {
          if (auth.isLockedOut) {
            return _LockedOutView(auth: auth);
          }
          return _UnlockView(auth: auth);
        }),
      ),
    );
  }
}

/// Tampilan Buka Kunci (Mockup 4)
class _UnlockView extends StatelessWidget {
  const _UnlockView({required this.auth});

  final AuthController auth;

  String _getInitials() {
    if (Get.isRegistered<ProfileController>()) {
      final initial = Get.find<ProfileController>().initial;
      if (initial.isNotEmpty) return initial;
    }
    return 'IF';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 40,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 20),
                    // Avatar Lingkaran Inisial IF
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.ink,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getInitials(),
                        style: AppText.display(
                          size: 26,
                          color: AppColors.paper,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Judul & Subtitle
                    Text(
                      'Selamat datang kembali',
                      textAlign: TextAlign.center,
                      style: AppText.display(size: 26),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Verifikasi untuk membuka',
                      textAlign: TextAlign.center,
                      style: AppText.body(size: 13, color: AppColors.mut),
                    ),
                    const SizedBox(height: 72),

                    // Tombol Sidik Jari Interaktif
                    Obx(() {
                      final status = auth.biometricStatus.value;
                      final isFailed = status == BiometricStatus.failed;
                      final isBusy = status == BiometricStatus.authenticating;

                      return Semantics(
                        button: true,
                        label: 'Verifikasi sidik jari',
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: isBusy
                                ? null
                                : () async {
                                    final success =
                                        await auth.unlockWithBiometric();
                                    if (success && context.mounted) {
                                      Get.offAllNamed(AppRoutes.home);
                                    }
                                  },
                            child: Container(
                              width: 130,
                              height: 130,
                              decoration: BoxDecoration(
                                color: isFailed
                                    ? AppColors.spendSoft
                                    : AppColors.paper2,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Container(
                                width: 106,
                                height: 106,
                                decoration: BoxDecoration(
                                  color: isFailed
                                      ? AppColors.spend
                                      : AppColors.ink,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: isBusy
                                    ? const SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: AppColors.paper,
                                        ),
                                      )
                                    : Icon(
                                        LucideIcons.fingerprint,
                                        size: 52,
                                        color: isFailed
                                            ? Colors.white
                                            : AppColors.paper,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),

                    // Lima titik menunjukkan sisa percobaan
                    Obx(() {
                      final failureCount = auth.biometricFailureCount.value;
                      final remaining =
                          (AppConstants.maxBiometricFailures - failureCount)
                              .clamp(0, AppConstants.maxBiometricFailures);

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          AppConstants.maxBiometricFailures,
                          (index) {
                            final isAvailable = index < remaining;
                            return Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isAvailable
                                    ? Colors.transparent
                                    : AppColors.spend.withValues(alpha: 0.6),
                                border: Border.all(
                                  color: isAvailable
                                      ? AppColors.line
                                      : AppColors.spend,
                                  width: 1.5,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 18),

                    // Keterangan ketuk ikon
                    Text(
                      'Ketuk ikon sidik jari untuk memulai',
                      textAlign: TextAlign.center,
                      style: AppText.body(size: 12.5, color: AppColors.mut),
                    ),
                  ],
                ),

                // Footer catatan gagal
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '5× gagal = dikunci 5:00',
                    textAlign: TextAlign.center,
                    style: AppText.mono(
                      size: 11,
                      color: AppColors.mut,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Tampilan Terkunci Hitung Mundur 5 Menit (Mockup 5)
class _LockedOutView extends StatefulWidget {
  const _LockedOutView({required this.auth});

  final AuthController auth;

  @override
  State<_LockedOutView> createState() => _LockedOutViewState();
}

class _LockedOutViewState extends State<_LockedOutView> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final until = widget.auth.biometricLockedUntil.value;
    if (until == null) {
      _remaining = Duration.zero;
      return;
    }
    final diff = until.difference(DateTime.now());
    if (diff.isNegative || diff.inSeconds <= 0) {
      _remaining = Duration.zero;
      _timer?.cancel();
      // Hitung mundur selesai, reset lockout agar pengguna bisa mencoba lagi
      widget.auth.clearLockout();
    } else {
      if (mounted) {
        setState(() => _remaining = diff);
      }
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ikon gembok di kotak merah muda
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: AppColors.spendSoft,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: const Icon(
                LucideIcons.lock,
                size: 38,
                color: AppColors.spend,
              ),
            ),
            const SizedBox(height: 28),

            // Judul
            Text(
              'Jeda sebentar.',
              textAlign: TextAlign.center,
              style: AppText.display(size: 28, height: 1.2),
            ),
            const SizedBox(height: 12),

            // Penjelasan
            Text(
              'Terlalu banyak percobaan biometrik. Demi keamanan, coba lagi setelah hitung mundur selesai.',
              textAlign: TextAlign.center,
              style: AppText.body(
                size: 13,
                color: AppColors.ink2,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),

            // Hitung Mundur 5:00
            Text(
              _formatDuration(_remaining),
              textAlign: TextAlign.center,
              style: AppText.display(
                size: 56,
                weight: FontWeight.w700,
                color: AppColors.spend,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 16),

            // Keterangan privasi data tetap tersembunyi
            Text(
              'Data keuanganmu tetap tersembunyi',
              textAlign: TextAlign.center,
              style: AppText.body(size: 12.5, color: AppColors.mut),
            ),
          ],
        ),
      ),
    );
  }
}
