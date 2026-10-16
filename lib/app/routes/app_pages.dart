import '../../core/services/data_refresh_service.dart';
import '../../features/transaction/repositories/transaction_repository.dart';
import 'package:get/get.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/pages/biometric_setup_page.dart';
import '../../features/auth/pages/biometric_unlock_page.dart';
import '../../features/auth/pages/pin_create_page.dart';
import '../../features/auth/pages/pin_unlock_page.dart';
import '../../features/auth/pages/login_page.dart';
import '../../features/budget/bindings/budget_binding.dart';
import '../../features/budget/views/budget_archive_page.dart';
import '../../features/category/controllers/category_controller.dart';
import '../../features/category/controllers/category_detail_controller.dart';
import '../../features/category/pages/category_detail_page.dart';
import '../../features/category/pages/category_manage_page.dart';
import '../../features/autodetect/pages/auto_detect_page.dart';
import '../../features/drafts/controllers/draft_controller.dart';
import '../../features/drafts/pages/drafts_page.dart';
import '../../features/drafts/repositories/draft_repository.dart';
import '../../features/recurring/controllers/recurring_controller.dart';
import '../../features/recurring/controllers/recurring_form_controller.dart';
import '../../features/recurring/pages/recurring_page.dart';
import '../../features/recurring/repositories/recurring_repository_impl.dart';
import '../../features/receipt/services/ml_kit_receipt_text_recognizer.dart';
import '../../features/receipt/services/receipt_ocr_service.dart';
import '../../features/receipt/views/receipt_review_page.dart';
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
      name: AppRoutes.categoryDetail,
      page: () => const CategoryDetailPage(),
      middlewares: [FinancialRouteGuard()],
      binding: BindingsBuilder(() {
        Get.put(CategoryDetailController(Get.find(), Get.find()));
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
    GetPage(
      name: AppRoutes.pinCreate,
      page: () => PinCreatePage(
        pinService: Get.find<AuthController>().pinService,
        onCreated: () => Get.offAllNamed(AppRoutes.home),
      ),
    ),
    GetPage(name: AppRoutes.pinUnlock, page: () => const PinUnlockPage()),
    GetPage(
      name: AppRoutes.autoDetect,
      page: () => const AutoDetectPage(),
      middlewares: [FinancialRouteGuard()],
    ),
    GetPage(
      name: AppRoutes.drafts,
      page: () => const DraftsPage(),
      middlewares: [FinancialRouteGuard()],
      binding: BindingsBuilder(() {
        Get.put(
          DraftController(
            Get.find<DraftRepository>(),
            Get.find<TransactionRepository>(),
          ),
        );
      }),
    ),
    GetPage(
      name: AppRoutes.recurring,
      page: () => const RecurringPage(),
      middlewares: [FinancialRouteGuard()],
      binding: BindingsBuilder(() {
        Get.put(
          RecurringController(Get.find<RecurringRepositoryImpl>()),
        );
        Get.put(RecurringFormController(Get.find<RecurringRepositoryImpl>()));
      }),
    ),
    GetPage(
      name: AppRoutes.receiptReview,
      page: () => const ReceiptReviewPage(),
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
