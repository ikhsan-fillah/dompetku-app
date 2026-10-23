import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/services/shared_prefs_service.dart';
import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/profile/controllers/profile_controller.dart';
import 'package:dompetku_app/features/profile/widgets/profile_header.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class _Prefs extends SharedPrefsService {
  String name = '';

  @override
  Future<String> getDisplayName() async => name;

  @override
  Future<void> setDisplayName(String value) async => name = value;

  @override
  Future<bool> getBiometricEnabled() async => false;

  @override
  Future<String> getThemeMode() async => 'light';

  @override
  Future<String> getLanguage() async => 'id';

  @override
  Future<int> getAutoLockSeconds() async => 0;
}

class _Transactions implements TransactionRepository {
  _Transactions(this.total, {this.fail = false});

  final int total;
  final bool fail;

  @override
  Future<List<TransactionModel>> getAll({DateRange? range}) async {
    if (fail) throw StateError('db');
    return List.generate(
      total,
      (i) => TransactionModel(
        id: i + 1,
        type: TransactionType.expense,
        title: 'T$i',
        amount: 1000,
        transactionDate: DateTime(2026, 10, 1),
        categoryId: 1,
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      ),
    );
  }

  @override
  Future<int> count({DateRange? range}) async {
    if (fail) throw StateError('db');
    return total;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Prefs prefs;

  ProfileController build({int count = 3, bool fail = false}) =>
      ProfileController(
        prefs,
        transactions: _Transactions(count, fail: fail),
        themeApplier: (_) {},
        languageApplier: (_) {},
      );

  Future<ProfileController> open(
    WidgetTester tester, {
    int count = 3,
    bool fail = false,
  }) async {
    final controller = build(count: count, fail: fail);
    await controller.load();
    await controller.loadTransactionCount();
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: ProfileHeader(controller: controller)),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  setUp(() => prefs = _Prefs());
  tearDown(Get.reset);

  testWidgets('tanpa nama menampilkan Friend dan jumlah transaksi', (
    tester,
  ) async {
    await open(tester, count: 128);

    expect(find.text('Friend'), findsOneWidget);
    expect(find.text('F'), findsOneWidget);
    expect(find.text('128 transaksi tercatat'), findsOneWidget);
    expect(find.textContaining('dompet'), findsNothing);
    expect(find.textContaining('Dikunci'), findsNothing);
  });

  testWidgets('satu transaksi memakai bentuk tunggal', (tester) async {
    await open(tester, count: 1);

    expect(find.text('1 transaksi tercatat'), findsOneWidget);
  });

  testWidgets('keterangan jumlah disembunyikan bila gagal dimuat', (
    tester,
  ) async {
    await open(tester, fail: true);

    expect(find.textContaining('transaksi tercatat'), findsNothing);
  });

  testWidgets('pensil membuka isian nama, simpan mengganti nama dan inisial', (
    tester,
  ) async {
    final controller = await open(tester);

    await tester.tap(find.byIcon(LucideIcons.pencil));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Kosongkan untuk memakai "Friend"'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Ikzy');
    await tester.tap(find.byIcon(LucideIcons.check));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(controller.displayName.value, 'Ikzy');
    expect(prefs.name, 'Ikzy');
    expect(find.text('Ikzy'), findsOneWidget);
    expect(find.text('I'), findsOneWidget);
  });

  testWidgets('isian nama bening supaya teks krem terbaca di kartu tinta', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.byIcon(LucideIcons.pencil));
    await tester.pumpAndSettle();

    final decoration = tester
        .widget<TextField>(find.byType(TextField))
        .decoration!;
    expect(decoration.filled, isFalse);
    expect(decoration.fillColor, Colors.transparent);
  });

  testWidgets('batal tidak mengubah nama', (tester) async {
    prefs.name = 'Ikzy';
    final controller = await open(tester);

    await tester.tap(find.byIcon(LucideIcons.pencil));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Lain');
    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pumpAndSettle();

    expect(controller.displayName.value, 'Ikzy');
    expect(prefs.name, 'Ikzy');
    expect(find.text('Ikzy'), findsOneWidget);
  });

  testWidgets('mengosongkan nama kembali ke Friend', (tester) async {
    prefs.name = 'Ikzy';
    final controller = await open(tester);

    await tester.tap(find.byIcon(LucideIcons.pencil));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.byIcon(LucideIcons.check));
    await tester.pumpAndSettle();

    expect(controller.displayName.value, '');
    expect(find.text('Friend'), findsOneWidget);
  });

  testWidgets('nama dibatasi 24 karakter', (tester) async {
    await open(tester);

    await tester.tap(find.byIcon(LucideIcons.pencil));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'a' * 40);

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'a' * 24,
    );
  });

  testWidgets('nama panjang tidak overflow di layar sempit', (tester) async {
    prefs.name = 'Nama Yang Sangat Panjang Sekali';
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await open(tester);

    expect(tester.takeException(), isNull);
  });
}
