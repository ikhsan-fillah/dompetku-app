import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constant/app_constant.dart';
import '../../../core/constant/domain_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/utils/display_name.dart';
import '../../profile/controllers/profile_controller.dart';
import '../utils/greeting.dart';
import '../controllers/auth_controller.dart';

/// Halaman Unlock Biometrik & Layar Terkunci sesuai Mockup 4 & 5:
/// - Unlock: sapaan sesuai jam, "Selamat datang kembali", kartu angka tersamar,
///   tombol sidik jari di bawah (merah saat gagal) dan lima titik sisa percobaan.
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

/// Tampilan Buka Kunci: sapaan sesuai jam, kartu angka tersamar, dan tombol
/// sidik jari di bawah supaya mudah dijangkau jempol.
class _UnlockView extends StatelessWidget {
  const _UnlockView({required this.auth});

  final AuthController auth;

  String _greetingName() {
    if (Get.isRegistered<ProfileController>()) {
      return Get.find<ProfileController>().greetingName;
    }
    return DisplayName.fallback;
  }

  /// "Selamat datang kembali" menjadi dua baris, kata terakhirnya miring.
  TextSpan _title(String text) {
    final words = text.split(' ');
    final head = words.length > 1
        ? words.sublist(0, words.length - 1).join(' ')
        : '';
    return TextSpan(
      children: [
        if (head.isNotEmpty) TextSpan(text: '$head\n'),
        TextSpan(
          text: '${words.last}.',
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Bisa di-scroll di layar pendek; di layar tinggi tombol tetap di bawah.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BrandRow(),
                  const SizedBox(height: 36),
                  Text(
                    '${timeGreeting(DateTime.now())}, ${_greetingName()}'
                        .toUpperCase(),
                    style: AppText.mono(
                      size: 12,
                      color: AppColors.ink2,
                      letterSpacing: 0.9,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text.rich(
                    _title('Selamat datang kembali'.tr),
                    style: AppText.display(
                      size: 44,
                      weight: FontWeight.w400,
                      height: 1.04,
                      letterSpacing: -0.9,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Verifikasi untuk membuka'.tr,
                    style: AppText.body(size: 15, color: AppColors.ink2),
                  ),
                  const SizedBox(height: 28),
                  const _MaskedSummary(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SizedBox(width: 4),
                      const Icon(
                        LucideIcons.eyeOff,
                        size: 14,
                        color: AppColors.ink2,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Data keuanganmu tetap tersembunyi'.tr,
                          style: AppText.body(
                            size: 12.5,
                            color: AppColors.ink2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Center(child: _UnlockControls(auth: auth)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'T',
          style: AppText.display(
            size: 20,
            weight: FontWeight.w700,
            color: AppColors.paper,
          ).copyWith(fontVariations: const [FontVariation('opsz', 12)]),
        ),
      ),
      const SizedBox(width: 10),
      Text('Tally', style: AppText.display(size: 20)),
      const Spacer(),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.lock, size: 14, color: AppColors.ink2),
            const SizedBox(width: 6),
            Text(
              'Terkunci'.tr,
              style: AppText.body(
                size: 12,
                weight: FontWeight.w700,
                color: AppColors.ink2,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Ringkasan dengan angka disamarkan: tidak ada data nyata sebelum lolos.
class _MaskedSummary extends StatelessWidget {
  const _MaskedSummary();

  @override
  Widget build(BuildContext context) {
    final labels = ['Saldo bulan ini'.tr, 'Pemasukan'.tr, 'Pengeluaran'.tr];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      labels[i],
                      style: AppText.body(size: 13, color: AppColors.ink2),
                    ),
                  ),
                  Text(
                    'Rp ••••••',
                    style: AppText.mono(
                      size: 14,
                      weight: FontWeight.w500,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            if (i < labels.length - 1)
              const Divider(height: 1, thickness: 1, color: AppColors.line2),
          ],
        ],
      ),
    );
  }
}

/// Tombol sidik jari, lima titik sisa percobaan, dan tautan PIN.
class _UnlockControls extends StatelessWidget {
  const _UnlockControls({required this.auth});

  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Obx(() {
          final status = auth.biometricStatus.value;
          final isFailed = status == BiometricStatus.failed;
          final isBusy = status == BiometricStatus.authenticating;

          return Semantics(
            button: true,
            label: 'Verifikasi sidik jari'.tr,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: isBusy
                    ? null
                    : () async {
                        final success = await auth.unlockWithBiometric();
                        if (success && context.mounted) {
                          Get.offAllNamed(AppRoutes.home);
                        }
                      },
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: isFailed ? AppColors.spendSoft : AppColors.paper2,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(
                      color: isFailed ? AppColors.spend : AppColors.ink,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x471A2724),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
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
                            color: isFailed ? Colors.white : AppColors.paper,
                          ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        Obx(() {
          final failureCount = auth.biometricFailureCount.value;
          final remaining = (AppConstants.maxBiometricFailures - failureCount)
              .clamp(0, AppConstants.maxBiometricFailures);

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(AppConstants.maxBiometricFailures, (index) {
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
                    color: isAvailable ? AppColors.mut : AppColors.spend,
                    width: 1.5,
                  ),
                ),
              );
            }),
          );
        }),
        const SizedBox(height: 14),
        Text(
          'Ketuk ikon sidik jari untuk memulai'.tr,
          textAlign: TextAlign.center,
          style: AppText.body(size: 13, color: AppColors.ink2),
        ),
        FutureBuilder<bool>(
          future: auth.hasPin(),
          builder: (context, snapshot) {
            if (snapshot.data != true) return const SizedBox(height: 12);
            return TextButton(
              onPressed: () => Get.offAllNamed(AppRoutes.pinUnlock),
              child: Text(
                'Pakai PIN'.tr,
                style: AppText.body(
                  size: 14,
                  weight: FontWeight.w700,
                  color: AppColors.ink,
                ).copyWith(decoration: TextDecoration.underline),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Text(
          '5 kali gagal = terkunci 5:00'.tr,
          textAlign: TextAlign.center,
          style: AppText.mono(
            size: 11,
            color: AppColors.ink2,
            letterSpacing: 0,
          ),
        ),
      ],
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
              'Jeda sebentar.'.tr,
              textAlign: TextAlign.center,
              style: AppText.display(size: 28, height: 1.2),
            ),
            const SizedBox(height: 12),

            // Penjelasan
            Text(
              'Terlalu banyak percobaan biometrik. Demi keamanan, coba lagi setelah hitung mundur selesai.'
                  .tr,
              textAlign: TextAlign.center,
              style: AppText.body(size: 13, color: AppColors.ink2, height: 1.5),
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
              'Data keuanganmu tetap tersembunyi'.tr,
              textAlign: TextAlign.center,
              style: AppText.body(size: 12.5, color: AppColors.mut),
            ),
          ],
        ),
      ),
    );
  }
}
