import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/constant/domain_enums.dart';
import '../controllers/auth_controller.dart';

class BiometricUnlockPage extends StatelessWidget {
  const BiometricUnlockPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('DompetKu terkunci')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Obx(() {
            final status = auth.biometricStatus.value;
            final lockedUntil = auth.biometricLockedUntil.value;
            final locked = auth.isLockedOut && lockedUntil != null;
            final label = locked
                ? 'Terlalu banyak percobaan. Coba lagi setelah ${TimeOfDay.fromDateTime(lockedUntil.toLocal()).format(context)}.'
                : status == BiometricStatus.unavailable
                ? 'Biometrik tidak tersedia pada perangkat ini.'
                : status == BiometricStatus.failed
                ? 'Autentikasi gagal. Silakan coba lagi.'
                : 'Autentikasi dengan biometrik untuk melihat data Anda.';
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: locked
                      ? null
                      : () async {
                          if (await auth.unlockWithBiometric() &&
                              context.mounted)
                            Get.offAllNamed(AppRoutes.home);
                        },
                  child: const Text('Buka dengan biometrik'),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
