import 'package:dompetku_app/features/auth/controllers/auth_controller.dart';
import 'package:dompetku_app/features/auth/models/app_session_model.dart';
import 'package:dompetku_app/features/auth/repositories/session_repository.dart';
import 'package:dompetku_app/features/splash/pages/splash_page.dart';
import 'package:dompetku_app/core/services/biometric_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _FakeSessionRepository implements SessionRepository {
  @override
  Future<AppSessionModel> read() async => const AppSessionModel(
    isRegistered: false,
    biometricEnabled: false,
    biometricFailureCount: 0,
  );

  @override
  Future<void> saveBiometricFailureState({
    required int count,
    DateTime? lockedUntil,
  }) async {}

  @override
  Future<void> setBiometricEnabled(bool value) async {}

  @override
  Future<void> setRegistered(bool value) async {}
}

class _FakeBiometricService implements BiometricService {
  @override
  Future<bool> authenticate() async => true;

  @override
  Future<bool> isAvailable() async => true;
}

void main() {
  tearDown(Get.reset);

  testWidgets('splash menampilkan indikator memuat', (tester) async {
    Get.put(AuthController(_FakeSessionRepository(), _FakeBiometricService()));
    await tester.pumpWidget(
      GetMaterialApp(
        home: const SplashPage(),
        getPages: [
          GetPage(name: '/login', page: () => const SizedBox()),
        ],
      ),
    );

    expect(find.text('DompetKu'), findsOneWidget);
    expect(find.text('Menyiapkan DompetKu'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
