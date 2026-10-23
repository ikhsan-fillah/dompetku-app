import 'package:dompetku_app/core/database/app_database.dart';
import 'package:dompetku_app/core/database/database_constants.dart';
import 'package:dompetku_app/core/database/migrations.dart';
import 'package:dompetku_app/core/state/resource_state.dart';
import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/core/widgets/sort_chip.dart';
import 'package:dompetku_app/features/category/controllers/category_detail_controller.dart';
import 'package:dompetku_app/features/category/data/category_local_data_source.dart';
import 'package:dompetku_app/features/category/pages/category_detail_page.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:dompetku_app/features/category/repositories/category_repository_impl.dart';
import 'package:dompetku_app/features/category/services/category_detail_service.dart';
import 'package:dompetku_app/features/transaction/data/transaction_local_data_source.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository_impl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MemoryAppDatabase extends AppDatabase {
  Database? _db;

  @override
  Future<Database> get database async {
    return _db ??= await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(version: 3, onCreate: Migrations.onCreate),
    );
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late _MemoryAppDatabase database;

  setUp(() async {
    database = _MemoryAppDatabase();
    Get.testMode = true;
    Get.put<TransactionRepository>(
      TransactionRepositoryImpl(TransactionLocalDataSource(database)),
    );
    Get.put<CategoryRepository>(
      CategoryRepositoryImpl(CategoryLocalDataSource(database)),
    );
    final db = await database.database;
    final now = DateTime.now().toUtc().toIso8601String();
    await db.insert(DatabaseTables.transactions, {
      DatabaseColumns.type: 'expense',
      DatabaseColumns.title: 'Kopi susu',
      DatabaseColumns.amount: 28000,
      DatabaseColumns.transactionDate: now,
      DatabaseColumns.categoryId: 1,
      DatabaseColumns.createdAt: now,
      DatabaseColumns.updatedAt: now,
    });
  });

  tearDown(() async {
    Get.reset();
    await database.close();
  });

  testWidgets('detail kategori selesai memuat, tidak berputar terus', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Text('awal')),
        getPages: [
          GetPage(
            name: '/detail',
            page: () => const CategoryDetailPage(),
            binding: BindingsBuilder(() {
              Get.put(CategoryDetailController(Get.find(), Get.find()));
            }),
          ),
        ],
      ),
    );
    Get.toNamed('/detail', arguments: {'categoryId': 1});
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    final controller = Get.find<CategoryDetailController>();
    expect(controller.state.value.status, ResourceStatus.success);
    expect(find.text('Kopi susu'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(SortChip<CategoryTransactionSort>), findsOneWidget);
  });
}
