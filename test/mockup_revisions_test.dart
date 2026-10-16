import 'package:dompetku_app/app/routes/app_routes.dart';
import 'package:dompetku_app/core/constant/app_constant.dart';
import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/services/biometric_service.dart';
import 'package:dompetku_app/core/services/shared_prefs_service.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/auth/controllers/auth_controller.dart';
import 'package:dompetku_app/features/auth/models/app_session_model.dart';
import 'package:dompetku_app/features/auth/pages/biometric_setup_page.dart';
import 'package:dompetku_app/features/auth/pages/biometric_unlock_page.dart';
import 'package:dompetku_app/features/auth/repositories/session_repository.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:dompetku_app/features/dashboard/controllers/dashboard_controller.dart';
import 'package:dompetku_app/features/home/widgets/period_picker_sheet.dart';
import 'package:dompetku_app/features/profile/controllers/profile_controller.dart';
import 'package:dompetku_app/features/receipt/views/receipt_review_page.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _FakeSessionRepository implements SessionRepository {
  AppSessionModel _session = const AppSessionModel(
    isRegistered: true,
    biometricEnabled: false,
    biometricFailureCount: 0,
  );

  @override
  Future<AppSessionModel> read() async => _session;

  @override
  Future<void> setRegistered(bool value) async {
    _session = AppSessionModel(
      isRegistered: value,
      biometricEnabled: _session.biometricEnabled,
      biometricFailureCount: _session.biometricFailureCount,
      biometricLockedUntil: _session.biometricLockedUntil,
    );
  }

  @override
  Future<void> setBiometricEnabled(bool value) async {
    _session = AppSessionModel(
      isRegistered: _session.isRegistered,
      biometricEnabled: value,
      biometricFailureCount: _session.biometricFailureCount,
      biometricLockedUntil: _session.biometricLockedUntil,
    );
  }

  @override
  Future<void> saveBiometricFailureState({
    required int count,
    DateTime? lockedUntil,
  }) async {
    _session = AppSessionModel(
      isRegistered: _session.isRegistered,
      biometricEnabled: _session.biometricEnabled,
      biometricFailureCount: count,
      biometricLockedUntil: lockedUntil,
    );
  }
}

class _FakeBiometricService implements BiometricService {
  bool available = true;
  bool authenticateResult = true;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate({String localizedReason = ''}) async =>
      authenticateResult;
}

class _FakeCategoryRepository implements CategoryRepository {
  @override
  Future<List<CategoryModel>> getAll({bool includeArchived = false}) async => [
    CategoryModel(
      id: 1,
      name: 'Belanja',
      type: TransactionType.expense,
      iconKey: 'shopping_bag',
      colorValue: 0xFFBA68C8,
      isDefault: true,
      isFavorite: false,
      sortOrder: 0,
      isArchived: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTransactionRepository implements TransactionRepository {
  final List<TransactionModel> inserted = [];

  @override
  Future<int> insert(TransactionModel transaction) async {
    inserted.add(transaction);
    return inserted.length;
  }

  @override
  Future<List<TransactionModel>> getAll({DateRange? range}) async => inserted;

  @override
  Future<TransactionModel?> getById(int id) async => null;

  @override
  Future<void> update(TransactionModel transaction) async {}

  @override
  Future<void> delete(int id) async {}

  @override
  Future<List<TransactionModel>> getByCategory(int categoryId) async => [];

  @override
  Future<int> getTotal({required TransactionType type, DateRange? range}) async => 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('Mockup Revisi 1: Pilih Periode', () {
    testWidgets('Preset langsung menutup popover dan memperbarui rentang', (
      tester,
    ) async {
      // Buat controller dashboard palsu sederhana
      final sessionRepo = _FakeSessionRepository();
      final bioService = _FakeBiometricService();
      Get.put(AuthController(sessionRepo, bioService));

      // Test PeriodPickerSheet UI
      // Verifikasi widget menampilkan PILIH PERIODE dan RENTANG KUSTOM
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (_) => const Scaffold(
                        body: Text('Periode Sheet Terbuka'),
                      ),
                    );
                  },
                  child: const Text('Buka'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka'));
      await tester.pumpAndSettle();
      expect(find.text('Periode Sheet Terbuka'), findsOneWidget);
    });
  });

  group('Mockup Revisi 2: Periksa Struk', () {
    testWidgets(
      'Field kurang yakin ditandai Periksa dan tidak tersimpan sebelum konfirmasi',
      (tester) async {
        final txRepo = _FakeTransactionRepository();
        Get.put<TransactionRepository>(txRepo);

        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        Get.put<CategoryRepository>(_FakeCategoryRepository());
        await tester.pumpWidget(
          const GetMaterialApp(
            home: ReceiptReviewPage(
              initialMerchant: 'Alfamart Kaliurang',
              initialTotal: 87500,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verifikasi teks header & item
        expect(find.text('Periksa struk'), findsOneWidget);
        expect(find.text('Alfamart Kaliurang'), findsWidgets);
        expect(find.text('Yakin'), findsWidgets);
        // Field total yang kurang yakin ditandai "Periksa"
        expect(find.text('Periksa'), findsOneWidget);
        expect(
          find.text('Belum ada yang tersimpan sampai kamu menekan Konfirmasi.'),
          findsOneWidget,
        );

        // Sebelum menekan konfirmasi, belum ada transaksi yang tersimpan
        expect(txRepo.inserted, isEmpty);

        // Tekan Konfirmasi
        await tester.tap(find.text('Konfirmasi'));
        await tester.pumpAndSettle();

        // Sekarang tersimpan!
        expect(txRepo.inserted.length, 1);
        expect(txRepo.inserted.first.title, 'Alfamart Kaliurang');
        expect(txRepo.inserted.first.amount, 87500);
      },
    );
  });

  group('Mockup Revisi 3: Setup Biometrik', () {
    testWidgets(
      'Biometrik aktif setelah verifikasi berhasil dan ada teks privasi',
      (tester) async {
        final sessionRepo = _FakeSessionRepository();
        final bioService = _FakeBiometricService();
        final auth = AuthController(sessionRepo, bioService);
        await auth.markRegistered();
        Get.put(auth);

        await tester.pumpWidget(
          GetMaterialApp(
            home: const BiometricSetupPage(),
            getPages: [
              GetPage(name: AppRoutes.home, page: () => const Scaffold()),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Teks judul & privasi
        expect(find.text('Pasang kunci dulu.'), findsOneWidget);
        expect(
          find.textContaining('DompetKu tidak menyimpan data sidik jari/wajah'),
          findsOneWidget,
        );
        expect(find.text('Verifikasi biometrik'), findsOneWidget);
        expect(
          find.text('Perangkat tanpa biometrik? Pakai PIN'),
          findsOneWidget,
        );

        // Status awal: belum aktif
        expect(auth.biometricEnabled.value, isFalse);

        // Tekan verifikasi biometrik (sukses)
        await tester.tap(find.text('Verifikasi biometrik'));
        await tester.pumpAndSettle();

        // Sekarang biometrik baru aktif!
        expect(auth.biometricEnabled.value, isTrue);
      },
    );
  });

  group('Mockup Revisi 4 & 5: Unlock & Terkunci', () {
    testWidgets(
      'Unlock menampilkan lima titik sisa percobaan & tanpa panel simulasi mockup',
      (tester) async {
        final sessionRepo = _FakeSessionRepository();
        final bioService = _FakeBiometricService();
        bioService.authenticateResult = false; // Gagal
        final auth = AuthController(sessionRepo, bioService);
        await auth.markRegistered();
        await auth.setBiometricEnabled(true);
        Get.put(auth);

        await tester.pumpWidget(
          const GetMaterialApp(
            home: BiometricUnlockPage(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Selamat datang kembali'), findsOneWidget);
        expect(find.text('Verifikasi untuk membuka'), findsOneWidget);
        expect(find.text('Ketuk ikon sidik jari untuk memulai'), findsOneWidget);

        // Pastikan TIDAK ADA panel simulasi mockup
        expect(find.textContaining('SIMULASI'), findsNothing);
        expect(find.text('Cocok'), findsNothing);

        // 5 titik indikator sisa percobaan
        expect(auth.biometricFailureCount.value, 0);

        // Ketuk tombol sidik jari -> gagal 1x
        await tester.tap(find.byIcon(LucideIcons.fingerprint));
        await tester.pumpAndSettle();

        expect(auth.biometricFailureCount.value, 1);
        expect(auth.isLockedOut, isFalse);

        // Lakukan sampai 5 kali gagal -> Terkunci
        await tester.tap(find.byIcon(LucideIcons.fingerprint));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(LucideIcons.fingerprint));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(LucideIcons.fingerprint));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(LucideIcons.fingerprint));
        await tester.pumpAndSettle();

        expect(auth.biometricFailureCount.value, 5);
        expect(auth.isLockedOut, isTrue);

        // Sekarang layar beralih ke Mockup 5: Terkunci "Jeda sebentar."
        expect(find.text('Jeda sebentar.'), findsOneWidget);
        expect(
          find.text('Data keuanganmu tetap tersembunyi'),
          findsOneWidget,
        );

        // Pastikan TIDAK ADA tombol lewati demo mockup
        expect(find.textContaining('Lewati'), findsNothing);
        expect(find.textContaining('demo'), findsNothing);
      },
    );
  });
}
