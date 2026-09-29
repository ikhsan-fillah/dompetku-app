import 'package:dompetku_app/core/database/app_database.dart';
import 'package:dompetku_app/features/budget/data/budget_local_data_source.dart';
import 'package:dompetku_app/features/budget/repositories/budget_repository.dart';
import 'package:dompetku_app/features/budget/repositories/budget_repository_impl.dart';
import 'package:dompetku_app/features/category/data/category_local_data_source.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:dompetku_app/features/category/repositories/category_repository_impl.dart';
import 'package:dompetku_app/features/transaction/data/transaction_local_data_source.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository_impl.dart';
import 'package:dompetku_app/core/services/secure_storage_service.dart';
import 'package:dompetku_app/core/services/shared_prefs_service.dart';
import 'package:dompetku_app/core/services/biometric_service.dart';
import 'package:dompetku_app/core/services/app_lock_service.dart';
import 'package:get/get.dart';
import 'package:dompetku_app/features/auth/controllers/auth_controller.dart';
import 'package:dompetku_app/features/auth/repositories/session_repository.dart';
import 'package:dompetku_app/features/auth/repositories/session_repository_impl.dart';
import 'package:dompetku_app/features/budget/controllers/budget_controller.dart';
import 'package:dompetku_app/features/category/controllers/category_controller.dart';
import 'package:dompetku_app/features/dashboard/controllers/dashboard_controller.dart';
import 'package:dompetku_app/features/dashboard/services/financial_calculation_service.dart';
import 'package:dompetku_app/features/profile/controllers/profile_controller.dart';
import 'package:dompetku_app/features/report/controllers/report_controller.dart';
import 'package:dompetku_app/features/transaction/controllers/transaction_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SecureStorageService(), permanent: true);
    Get.put(SharedPrefsService(), permanent: true);
    Get.put<BiometricService>(LocalAuthBiometricService(), permanent: true);
    Get.put(AppLockService(), permanent: true);
    Get.put(AppDatabase(), permanent: true);
    Get.put(CategoryLocalDataSource(Get.find()), permanent: true);
    Get.put(TransactionLocalDataSource(Get.find()), permanent: true);
    Get.put(BudgetLocalDataSource(Get.find()), permanent: true);
    Get.put<CategoryRepository>(CategoryRepositoryImpl(Get.find()), permanent: true);
    Get.put<TransactionRepository>(TransactionRepositoryImpl(Get.find()), permanent: true);
    Get.put<BudgetRepository>(BudgetRepositoryImpl(Get.find()), permanent: true);
    Get.put<SessionRepository>(SessionRepositoryImpl(Get.find()), permanent: true);
    Get.put(const FinancialCalculationService(), permanent: true);
    Get.put(AuthController(Get.find(), Get.find()), permanent: true);
    Get.lazyPut(() => CategoryController(Get.find()), fenix: true);
    Get.lazyPut(() => TransactionController(Get.find()), fenix: true);
    Get.lazyPut(() => BudgetController(Get.find()), fenix: true);
    Get.lazyPut(() => DashboardController(Get.find(), Get.find(), Get.find()), fenix: true);
    Get.lazyPut(() => ReportController(Get.find(), Get.find()), fenix: true);
    Get.lazyPut(() => ProfileController(Get.find()), fenix: true);
  }
}
