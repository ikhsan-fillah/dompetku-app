import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/constant/domain_enums.dart';
import '../../../core/widgets/auth_scaffold.dart';
import '../controllers/auth_controller.dart';

class BiometricUnlockPage extends StatelessWidget {
  const BiometricUnlockPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return AuthScaffold(
      icon: Icons.lock_open_rounded,
      title: 'Selamat datang kembali',
      description: 'Verifikasi identitas untuk membuka ringkasan keuanganmu.',
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
            Text(message),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: busy || locked
                  ? null
                  : () async {
                      if (await auth.unlockWithBiometric() && context.mounted) {
                        Get.offAllNamed(AppRoutes.home);
                      }
                    },
              icon: const Icon(Icons.fingerprint_rounded),
              label: Text(busy ? 'Memverifikasi…' : 'Buka dengan biometrik'),
            ),
          ],
        );
      }),
    );
  }
}
