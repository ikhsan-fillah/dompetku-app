import 'dart:nativewrappers/_internal/vm/lib/ffi_native_type_patch.dart';

import 'package:dompetku_app/app/routes/app_routes.dart';
import 'package:dompetku_app/features/auth/controllers/auth_controller.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  final AuthController _auth = Get.find<AuthController>();

  Future<void> decideNextPage() async{
    await Future<Void>.delayed(const Duration(milliseconds: 500));

    _auth.lock();

    if(!_auth.isRegistered.value){
      Get.offAllNamed(AppRoutes.login);
      return;
    }
    Get.offAllNamed(AppRoutes.home);
  }
}