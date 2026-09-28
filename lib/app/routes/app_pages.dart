import 'package:get/get.dart';
import 'package:dompetku_app/app/routes/app_routes.dart';
import 'package:dompetku_app/features/splash/pages/splash_page.dart';
import 'package:dompetku_app/features/auth/pages/login_page.dart';
import 'package:dompetku_app/features/home/pages/home_page.dart';
import 'package:dompetku_app/features/auth/pages/biometric_setup_page.dart';
import 'package:dompetku_app/features/auth/pages/biometric_unlock_page.dart';

class AppPages {
  static final pages = <GetPage>[
    GetPage(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage(name: AppRoutes.login, page: () => const LoginPage()),
    GetPage(name: AppRoutes.home, page: () => const HomePage()),
    GetPage(name: AppRoutes.biometricSetup, page: () => const BiometricSetupPage()),
    GetPage(name: AppRoutes.biometricUnlock, page: () => const BiometricUnlockPage()),
  ];
}
