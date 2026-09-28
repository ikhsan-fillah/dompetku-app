import 'package:dompetku_app/app/routes/app_routes.dart';
import 'package:dompetku_app/features/auth/controllers/auth_controller.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  final AuthController _auth = Get.find<AuthController>();

  Future<void> decideNextPage() async {
    await _auth.initialization;
    _auth.lock();

    if (!_auth.isRegistered.value) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }
    Get.offAllNamed(
      _auth.biometricEnabled.value
          ? AppRoutes.biometricUnlock
          : AppRoutes.biometricSetup,
    );
  }
}
