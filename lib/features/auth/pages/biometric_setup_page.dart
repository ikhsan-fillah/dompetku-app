import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constant/domain_enums.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../controllers/auth_controller.dart';

class BiometricSetupPage extends StatelessWidget {
  const BiometricSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return AuthScaffold(
      icon: Icons.fingerprint_rounded,
      title: 'Lindungi dompetmu',
      description:
          'Aktifkan biometrik agar catatan keuangan hanya terlihat setelah kamu mengizinkannya.',
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
            Text(message),
            const SizedBox(height: 24),
            AppButton(
              expand: true,
              onPressed: busy || locked
                  ? null
                  : () async {
                      if (await auth.setupBiometric() && context.mounted) {
                        Get.offAllNamed(AppRoutes.home);
                      }
                    },
              icon: Icons.verified_user_outlined,
              label: busy ? 'Memverifikasi…' : 'Verifikasi biometrik',
            ),
          ],
        );
      }),
    );
  }
}
