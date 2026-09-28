import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'core/services/app_lock_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/controllers/auth_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

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
    if (!Get.isRegistered<AppLockService>() || !Get.isRegistered<AuthController>()) {
      return;
    }
    final lockService = Get.find<AppLockService>();
    final auth = Get.find<AuthController>();
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      lockService.onBackgrounded(DateTime.now());
    } else if (state == AppLifecycleState.resumed && auth.isUnlocked.value) {
      if (lockService.shouldLock(DateTime.now())) {
        auth.lock();
        Get.offAllNamed(AppRoutes.biometricUnlock);
      }
      lockService.onForegrounded();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}

