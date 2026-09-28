import 'package:get/get.dart';
import 'package:dompetku_app/app/routes/app_routes.dart';
import 'package:dompetku_app/features/splash/pages/splash_page.dart';
import 'package:dompetku_app/features/auth/pages/login_page.dart';
import 'package:dompetku_app/features/home/pages/home_page.dart';
import 'package:dompetku_app/features/auth/pages/create_pin_page.dart';
import 'package:dompetku_app/features/auth/pages/unlock_pin_page.dart';
import 'package:dompetku_app/features/splash/pages/splash_page.dart';

class AppPages {
  static final pages = <GetPage>[
    GetPage(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage(name: AppRoutes.login, page: () => const LoginPage()),
    GetPage(name: AppRoutes.home, page: () => const HomePage()),
    GetPage(name: AppRoutes.createPin, page: () => const CreatePinPage()),
    GetPage(name: AppRoutes.unlockPin, page: () => const UnlockPinPage()),
    GetPage(name: AppRoutes.splash, page: () => const SplashPage()),
  ];
}