import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'core/services/app_lock_service.dart';
import 'core/i18n/app_language.dart';
import 'core/i18n/app_translations.dart';
import 'core/services/app_version.dart';
import 'core/services/data_refresh_service.dart';
import 'core/services/shared_prefs_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/controllers/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemStatusBarContrastEnforced: false,
    ),
  );
  await AppVersion.init();
  final language = await SharedPrefsService().getLanguage();
  runApp(MyApp(language: language));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.language = AppLanguage.defaultCode});

  final String language;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!Get.isRegistered<AuthController>() ||
        !Get.isRegistered<AppLockService>()) {
      return;
    }
    final lockService = Get.find<AppLockService>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      lockService.onBackgrounded(DateTime.now());
      return;
    }
    if (state != AppLifecycleState.resumed) return;

    final auth = Get.find<AuthController>();
    if (auth.biometricEnabled.value && lockService.shouldLock(DateTime.now())) {
      auth.lock();
      lockService.onForegrounded();
      if (Get.currentRoute != AppRoutes.biometricUnlock) {
        Get.offAllNamed(AppRoutes.biometricUnlock);
      }
      return;
    }
    lockService.onForegrounded();
    if (auth.isUnlocked.value && Get.isRegistered<DataRefreshService>()) {
      Get.find<DataRefreshService>().bump();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: AppLanguage.localeFor(widget.language),
      fallbackLocale: AppLanguage.localeFor(AppLanguage.defaultCode),
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      // Kartu yang digeser menutup sendiri saat kartu lain dibuka.
      builder: (context, child) =>
          SlidableAutoCloseBehavior(child: child ?? const SizedBox()),
    );
  }
}
