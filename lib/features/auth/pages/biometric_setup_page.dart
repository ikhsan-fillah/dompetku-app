import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constant/domain_enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../controllers/auth_controller.dart';

class BiometricSetupPage extends StatelessWidget {
  const BiometricSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return AuthScaffold(
      icon: LucideIcons.fingerprint,
      kicker: 'KUNCI',
      step: '02 / 02',
      title: 'Lindungi dompetmu',
      description:
          'Aktifkan biometrik agar catatan keuangan hanya terlihat setelah kamu mengizinkannya.',
      hero: Obx(() {
        final status = auth.biometricStatus.value;
        return AuthOrb(
          icon: status == BiometricStatus.authenticated
              ? LucideIcons.check
              : LucideIcons.fingerprint,
          failed: status == BiometricStatus.failed,
        );
      }),
      child: Obx(() {
        final status = auth.biometricStatus.value;
        final until = auth.biometricLockedUntil.value;
        final locked = auth.isLockedOut;
        final busy = status == BiometricStatus.authenticating;
        final message = locked
            ? 'Terlalu banyak percobaan. Coba lagi setelah ${until == null ? '-' : TimeOfDay.fromDateTime(until.toLocal()).format(context)}.'
            : status == BiometricStatus.unavailable
            ? 'Biometrik tidak tersedia. Daftarkan biometrik di pengaturan perangkat, lalu coba lagi.'
            : status == BiometricStatus.failed
            ? 'Verifikasi gagal. Coba lagi.'
            : 'Verifikasi biometrik sekali untuk menyelesaikan pengaturan.';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message,
              style: AppText.body(
                size: 12,
                color: status == BiometricStatus.failed || locked
                    ? AppColors.spend
                    : AppColors.ink2,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              expand: true,
              onPressed: busy || locked
                  ? null
                  : () async {
                      if (await auth.setupBiometric() && context.mounted) {
                        Get.offAllNamed(AppRoutes.home);
                      }
                    },
              icon: LucideIcons.fingerprint,
              label: busy ? 'Memverifikasi...' : 'Verifikasi biometrik',
            ),
          ],
        );
      }),
    );
  }
}
