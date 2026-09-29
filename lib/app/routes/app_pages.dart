import 'package:get/get.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/pages/biometric_setup_page.dart';
import '../../features/auth/pages/biometric_unlock_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/home/pages/home_page.dart';
import '../../features/splash/pages/splash_page.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = <GetPage>[
    GetPage(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage(name: AppRoutes.login, page: () => const LoginPage()),
    GetPage(
      name: AppRoutes.home,
      page: () => const HomePage(),
      middlewares: [FinancialRouteGuard()],
    ),
    GetPage(name: AppRoutes.biometricSetup, page: () => const BiometricSetupPage()),
    GetPage(name: AppRoutes.biometricUnlock, page: () => const BiometricUnlockPage()),
  ];
}

class FinancialRouteGuard extends GetMiddleware {
  @override
  GetPage? onPageCalled(GetPage? page) {
    if (page == null) return null;
    if (!Get.isRegistered<AuthController>() ||
        !Get.find<AuthController>().isUnlocked.value) {
      return page.copy(name: AppRoutes.splash, page: () => const SplashPage());
    }
    return page;
  }
}
