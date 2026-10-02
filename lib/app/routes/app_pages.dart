import 'package:get/get.dart';

import '../../core/services/data_refresh_service.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/pages/biometric_setup_page.dart';
import '../../features/auth/pages/biometric_unlock_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/budget/bindings/budget_binding.dart';
import '../../features/budget/models/budget_model.dart';
import '../../features/budget/views/budget_archive_page.dart';
import '../../features/budget/views/budget_form_page.dart';
import '../../features/category/controllers/category_controller.dart';
import '../../features/category/pages/category_manage_page.dart';
import '../../features/receipt/services/ml_kit_receipt_text_recognizer.dart';
import '../../features/receipt/services/receipt_ocr_service.dart';
import '../../features/report/views/report_page.dart';
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
          () => TransactionFormController(
            Get.find(),
            Get.find(),
            ocr: ReceiptOcrService(MlKitReceiptTextRecognizer()),
          ),
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
      name: AppRoutes.budgetArchive,
      page: () => const BudgetArchivePage(),
      middlewares: [FinancialRouteGuard()],
      binding: BudgetBinding(),
    ),
    GetPage(
      name: AppRoutes.categories,
      page: () => const CategoryManagePage(),
      middlewares: [FinancialRouteGuard()],
      binding: BindingsBuilder(() {
        if (!Get.isRegistered<CategoryController>()) {
          Get.put(CategoryController(Get.find()));
        }
      }),
    ),
    GetPage(
      name: AppRoutes.report,
      page: () => const ReportPage(),
      middlewares: [FinancialRouteGuard()],
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

/// Aplikasi pribadi: cukup sudah pernah login (terdaftar) untuk masuk.
class FinancialRouteGuard extends GetMiddleware {
  @override
  GetPage? onPageCalled(GetPage? page) {
    if (page == null) return null;
    if (!Get.isRegistered<AuthController>() ||
        !Get.find<AuthController>().isRegistered.value) {
      return page.copy(name: AppRoutes.splash, page: () => const SplashPage());
    }
    return page;
  }
}
