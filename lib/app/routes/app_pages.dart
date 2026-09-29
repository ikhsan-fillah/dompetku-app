import 'package:get/get.dart';


import '../../core/services/data_refresh_service.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/pages/biometric_setup_page.dart';
import '../../features/auth/pages/biometric_unlock_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/budget/bindings/budget_binding.dart';
import '../../features/budget/models/budget_model.dart';
import '../../features/budget/views/budget_form_page.dart';
import '../../features/shell/controllers/main_shell_controller.dart';
import '../../features/shell/pages/main_shell_page.dart';
import '../../features/splash/pages/splash_page.dart';
import '../../features/transaction/controllers/transaction_form_controller.dart';
import 'app_routes.dart';


class AppPages {
  static final pages = <GetPage>[
    GetPage(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage(name: AppRoutes.login, page: () => const LoginPage()),
    GetPage(
      name: AppRoutes.home,
      page: () => const MainShellPage(),
      middlewares: [FinancialRouteGuard()],
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<DataRefreshService>()) {
          Get.put(DataRefreshService(), permanent: true);
        }
        Get.put(MainShellController());
        Get.lazyPut(
          () => TransactionFormController(Get.find(), Get.find()),
          fenix: true,
        );
        BudgetBinding().dependencies();
      }),
    ),
    GetPage(
      name: AppRoutes.budgetForm,
      page: () => BudgetFormPage(budget: Get.arguments as BudgetModel?),
      middlewares: [FinancialRouteGuard()],
      binding: BudgetBinding(),
    ),
    GetPage(
      name: AppRoutes.biometricSetup,
      page: () => const BiometricSetupPage(),
    ),
    GetPage(
      name: AppRoutes.biometricUnlock,
      page: () => const BiometricUnlockPage(),
    ),
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
