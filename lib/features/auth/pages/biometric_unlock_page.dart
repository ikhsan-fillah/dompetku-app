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

class BiometricUnlockPage extends StatelessWidget {
  const BiometricUnlockPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return AuthScaffold(
      icon: LucideIcons.lockOpen,
      sheet: false,
      title: 'Selamat datang kembali',
      description: 'Verifikasi identitas untuk membuka ringkasan keuanganmu.',
      hero: Obx(() {
        final status = auth.biometricStatus.value;
        return AuthOrb(
          icon: LucideIcons.fingerprint,
          dark: false,
          failed: status == BiometricStatus.failed,
        );
      }),
      child: Obx(() {
        final status = auth.biometricStatus.value;
        final until = auth.biometricLockedUntil.value;
        final locked = auth.isLockedOut;
        final busy = status == BiometricStatus.authenticating;
        final message = locked
            ? 'Terkunci sementara sampai ${until == null ? '-' : TimeOfDay.fromDateTime(until.toLocal()).format(context)}.'
            : status == BiometricStatus.unavailable
            ? 'Biometrik tidak tersedia. Periksa pengaturan perangkat.'
            : status == BiometricStatus.failed
            ? 'Autentikasi gagal. Silakan coba lagi.'
            : 'Data keuanganmu tersimpan hanya di perangkat ini.';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.body(
                size: 12.5,
                color: status == BiometricStatus.failed || locked
                    ? AppColors.spend
                    : AppColors.mut,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              expand: true,
              onPressed: busy || locked
                  ? null
                  : () async {
                      if (await auth.unlockWithBiometric() && context.mounted) {
                        Get.offAllNamed(AppRoutes.home);
                      }
                    },
              icon: LucideIcons.fingerprint,
              label: busy ? 'Memverifikasi...' : 'Buka dengan biometrik',
            ),
          ],
        );
      }),
    );
  }
}
