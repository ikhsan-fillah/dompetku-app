import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dompetku_app/app/routes/app_routes.dart';
import 'package:dompetku_app/features/auth/controllers/auth_controller.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Page'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await auth.markRegistered();
            auth.lock();
            Get.offAllNamed(AppRoutes.biometricSetup);
          }, 
        child: const Text('simulasi login sukses'),)
      )
    );
  }
}
