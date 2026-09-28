import 'package:dompetku_app/core/services/secure_storage_service.dart';
import 'package:dompetku_app/core/services/shared_prefs_service.dart';
import 'package:get/get.dart';
import 'package:dompetku_app/features/auth/controllers/auth_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthController(), permanent: true);
    Get.put(SecureStorageService(), permanent: true);
    Get.put(SharedPrefsService(), permanent: true);
  }
}