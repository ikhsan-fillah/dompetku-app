import 'dart:async';

import 'package:dompetku_app/features/recap/services/recap_calculation_service.dart';
import 'package:dompetku_app/core/services/data_refresh_service.dart';
import 'package:dompetku_app/core/database/app_database.dart';
import 'package:dompetku_app/core/services/app_lock_service.dart';
import 'package:dompetku_app/core/services/biometric_service.dart';
import 'package:dompetku_app/core/services/local_data_reset_service.dart';
import 'package:dompetku_app/core/services/pin_service.dart';
import 'package:dompetku_app/features/drafts/data/draft_local_data_source.dart';
import 'package:dompetku_app/features/drafts/repositories/draft_repository.dart';
import 'package:dompetku_app/features/recurring/services/recurring_runner.dart';
import 'package:dompetku_app/features/autodetect/services/auto_detect_service.dart';
import 'package:dompetku_app/features/recurring/data/recurring_local_data_source.dart';
import 'package:dompetku_app/features/recurring/repositories/recurring_repository_impl.dart';
import 'package:dompetku_app/features/recurring/services/recurring_generator.dart';
import 'package:dompetku_app/features/recurring/services/recurring_reminders.dart';
import 'package:dompetku_app/core/widgets/app_toast.dart';
import 'package:dompetku_app/core/services/secure_storage_service.dart';
import 'package:dompetku_app/core/services/shared_prefs_service.dart';
import 'package:dompetku_app/features/auth/controllers/auth_controller.dart';
import 'package:dompetku_app/features/auth/repositories/session_repository.dart';
import 'package:dompetku_app/features/auth/repositories/session_repository_impl.dart';
import 'package:dompetku_app/features/budget/controllers/budget_controller.dart';
import 'package:dompetku_app/features/budget/data/budget_local_data_source.dart';
import 'package:dompetku_app/features/budget/repositories/budget_repository.dart';
import 'package:dompetku_app/features/budget/repositories/budget_repository_impl.dart';
import 'package:dompetku_app/features/category/controllers/category_controller.dart';
import 'package:dompetku_app/features/category/data/category_local_data_source.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:dompetku_app/features/category/repositories/category_repository_impl.dart';
import 'package:dompetku_app/features/dashboard/controllers/dashboard_controller.dart';
import 'package:dompetku_app/features/dashboard/services/financial_calculation_service.dart';
import 'package:dompetku_app/features/profile/controllers/profile_controller.dart';
import 'package:dompetku_app/features/report/controllers/report_controller.dart';
import 'package:dompetku_app/features/transaction/controllers/transaction_controller.dart';
import 'package:dompetku_app/features/transaction/data/transaction_local_data_source.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository_impl.dart';
import 'package:get/get.dart';
import 'package:dompetku_app/features/widget/home_widget_service.dart';
import 'package:dompetku_app/features/shell/controllers/main_shell_controller.dart';
import 'package:dompetku_app/features/transaction/widgets/transaction_form_sheet.dart';
import 'package:dompetku_app/features/goals/controllers/goals_controller.dart';
import 'package:dompetku_app/features/goals/data/goal_repository.dart';
import '../../features/transaction/controllers/transaction_form_controller.dart';
import '../../features/recurring/models/recurring_rule.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SecureStorageService(), permanent: true);
    Get.put(SharedPrefsService(), permanent: true);
    Get.put<BiometricService>(LocalAuthBiometricService(), permanent: true);
    Get.put(AppLockService(), permanent: true);
    Get.put(AppDatabase(), permanent: true);
    Get.put(
      LocalDataResetService(Get.find(), Get.find(), Get.find()),
      permanent: true,
    );
    Get.put(CategoryLocalDataSource(Get.find()), permanent: true);
    Get.put(TransactionLocalDataSource(Get.find()), permanent: true);
    Get.put(BudgetLocalDataSource(Get.find()), permanent: true);
    Get.put<CategoryRepository>(
      CategoryRepositoryImpl(Get.find()),
      permanent: true,
    );
    Get.put<TransactionRepository>(
      TransactionRepositoryImpl(Get.find()),
      permanent: true,
    );
    Get.put<BudgetRepository>(
      BudgetRepositoryImpl(Get.find()),
      permanent: true,
    );
    Get.put<SessionRepository>(
      SessionRepositoryImpl(Get.find()),
      permanent: true,
    );
    Get.put(const FinancialCalculationService(), permanent: true);
    Get.put(
      RecapCalculationService(Get.find<FinancialCalculationService>()),
      permanent: true,
    );
    Get.put<DraftRepository>(
      DraftRepositoryImpl(DraftLocalDataSource(Get.find<AppDatabase>())),
      permanent: true,
    );
    Get.put(
      RecurringRepositoryImpl(
        RecurringLocalDataSource(Get.find<AppDatabase>()),
      ),
      permanent: true,
    );
    final reminders = Get.put(
      RecurringReminderService(
        store: Get.find<RecurringRepositoryImpl>(),
        transactions: Get.find<TransactionRepository>(),
        dailyConfig: () async {
          final prefs = Get.find<SharedPrefsService>();
          return DailyReminderConfig(
            enabled: await prefs.getDailyReminderEnabled(),
            minutes: await prefs.getDailyReminderMinutes(),
          );
        },
      ),
      permanent: true,
    );
    unawaited(reminders.init());
    final widgets = Get.put(
      HomeWidgetService(
        transactions: Get.find<TransactionRepository>(),
        budgets: Get.find<BudgetRepository>(),
        categories: Get.find<CategoryRepository>(),
      ),
      permanent: true,
    );
    unawaited(widgets.init());
    final auth = AuthController(
      Get.find(),
      Get.find(),
      pinService: PinService(Get.find<SecureStorageService>()),
    );
    Get.put(
      AutoDetectService(
        Get.find<DraftRepository>(),
        transactions: Get.find<TransactionRepository>(),
        categories: Get.find<CategoryRepository>(),
      ),
      permanent: true,
    );
    // Tombol "Catat" di pengingat: catat setelah kunci dibuka.
    Future<void> recordFromReminder() async {
      final name = await reminders.consumePendingRecord();
      if (name == null) return;
      AppToast.show(
        title: '@name tercatat'.trParams({'name': name}),
        message: 'Dari pengingat transaksi berulang'.tr,
      );
      if (Get.isRegistered<DataRefreshService>()) {
        Get.find<DataRefreshService>().bump();
      }
    }

    reminders.onRecordRequested = () {
      if (auth.isUnlocked.value) unawaited(recordFromReminder());
    };

    // Badan notifikasi diketuk: buka Catat Keuangan (terisi untuk berulang).
    Future<void> openFromReminder() async {
      final open = reminders.takePendingOpen();
      if (open == null) return;
      final ruleId = open.ruleId;
      final rule = ruleId == null ? null : await reminders.ruleById(ruleId);
      await Future<void>.delayed(const Duration(milliseconds: 700));
      final context = Get.context;
      if (context == null || !context.mounted) return;
      await showTransactionSheet(
        context,
        initialMode: rule?.type == RecurringType.income
            ? FinancialInputMode.income
            : FinancialInputMode.expense,
        prefill: rule == null
            ? null
            : TransactionPrefill(
                title: rule.name,
                amount: rule.amount,
                categoryId: rule.categoryId,
              ),
      );
    }

    reminders.onOpenRequested = () {
      if (auth.isUnlocked.value) unawaited(openFromReminder());
    };

    // Ketukan widget: jalankan setelah kunci dibuka dan Beranda tampil.
    Future<void> runWidgetAction() async {
      final action = widgets.takePendingAction();
      if (action == null || action == WidgetAction.open) return;
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (action == WidgetAction.openBudget) {
        if (Get.isRegistered<MainShellController>()) {
          Get.find<MainShellController>().select(2);
        }
        return;
      }
      final context = Get.context;
      if (context == null || !context.mounted) return;
      await showTransactionSheet(
        context,
        initialMode: action == WidgetAction.addIncome
            ? FinancialInputMode.income
            : FinancialInputMode.expense,
      );
    }

    widgets.onAction = () {
      if (auth.isUnlocked.value) unawaited(runWidgetAction());
    };
    auth.onUnlocked = () async {
      if (Get.isRegistered<AutoDetectService>()) {
        Get.find<AutoDetectService>().start();
      }
      await recordFromReminder();
      unawaited(openFromReminder());
      unawaited(runWidgetAction());
      await RecurringRunner(
        rules: Get.find<RecurringRepositoryImpl>(),
        transactions: Get.find<TransactionRepository>(),
        generator: const RecurringGenerator(),
        drafts: RecurringDraftSink(Get.find<DraftRepository>()),
      ).runDue(DateTime.now());
      unawaited(reminders.reschedule());
      unawaited(widgets.update());
      if (Get.isRegistered<DataRefreshService>()) {
        Get.find<DataRefreshService>().bump();
      }
    };
    Get.put(auth, permanent: true);
    Get.lazyPut(() => CategoryController(Get.find()), fenix: true);
    Get.lazyPut(() => TransactionController(Get.find()), fenix: true);
    Get.lazyPut(() => BudgetController(Get.find()), fenix: true);
    Get.lazyPut<GoalRepository>(
      () => GoalRepositoryImpl(Get.find<AppDatabase>()),
      fenix: true,
    );
    Get.lazyPut(() => GoalsController(Get.find<GoalRepository>()), fenix: true);
    Get.lazyPut(
      () => DashboardController(Get.find(), Get.find(), Get.find()),
      fenix: true,
    );
    Get.lazyPut(
      () => ReportController(Get.find(), Get.find(), Get.find()),
      fenix: true,
    );
    // Tipe eksplisit: parameter ProfileController bertipe nullable, sehingga
    // Get.find() tanpa tipe akan mencari 'Tipe?' dan gagal ditemukan.
    Get.lazyPut(
      () => ProfileController(
        Get.find<SharedPrefsService>(),
        resetService: Get.find<LocalDataResetService>(),
        authController: Get.find<AuthController>(),
        transactions: Get.find<TransactionRepository>(),
      ),
      fenix: true,
    );
  }
}
