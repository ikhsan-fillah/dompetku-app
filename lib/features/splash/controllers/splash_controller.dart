import 'package:dompetku_app/app/routes/app_routes.dart';
import 'package:dompetku_app/features/auth/controllers/auth_controller.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  final AuthController _auth = Get.find<AuthController>();

  static const _minimumSplash = Duration(milliseconds: 2200);

  /// Menunggu sesi terbaca (dan splash tampil minimal sebentar), lalu:
  /// belum login -> halaman login, sudah login -> langsung beranda.
  Future<void> decideNextPage() async {
    await Future.wait<void>([
      _auth.initialization,
      Future<void>.delayed(_minimumSplash),
    ]);

    if (!_auth.isRegistered.value) {
      Get.offAllNamed(AppRoutes.login);
      return;
    }
    if (_auth.biometricEnabled.value) {
      _auth.lock();
      Get.offAllNamed(AppRoutes.biometricUnlock);
    } else {
      _auth.unlock();
      Get.offAllNamed(AppRoutes.home);
    }
  }
}
