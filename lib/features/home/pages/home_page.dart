import 'package:dompetku_app/app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dompetku_app/features/auth/controllers/auth_controller.dart';
import 'package:dompetku_app/features/auth/widgets/lock_overlay.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: Obx(() {
        return Stack(
          children: [
            const Center(
              child: Text('Konten Home'),
            ),
            if (!auth.isUnlocked.value)
              LockOverlay(
                hasPin: auth.hasPin.value,
                onUnlockTap: () {
                  if(!auth.hasPin.value){
                    Get.toNamed(AppRoutes.createPin);
                    return;
                  }
                  Get.toNamed(AppRoutes.unlockPin);
                },
              ),
          ],
        );
      }),
    );
  }
}
