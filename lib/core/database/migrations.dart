import 'package:sqflite/sqflite.dart';

import '../constant/app_constant.dart';
import 'database_constants.dart';

class Migrations {
  static Future<void> onCreate(Database db, int version) async {
    await db.execute('''
			CREATE TABLE ${DatabaseTables.categories} (
				${DatabaseColumns.id} INTEGER PRIMARY KEY AUTOINCREMENT,
				${DatabaseColumns.name} TEXT NOT NULL,
				${DatabaseColumns.type} TEXT NOT NULL CHECK (${DatabaseColumns.type} IN ('income', 'expense')),
				${DatabaseColumns.iconKey} TEXT NOT NULL,
				${DatabaseColumns.colorValue} INTEGER NOT NULL,
				${DatabaseColumns.isDefault} INTEGER NOT NULL DEFAULT 0,
				${DatabaseColumns.isFavorite} INTEGER NOT NULL DEFAULT 0,
				${DatabaseColumns.sortOrder} INTEGER NOT NULL DEFAULT 0,
				${DatabaseColumns.isArchived} INTEGER NOT NULL DEFAULT 0,
				${DatabaseColumns.createdAt} TEXT NOT NULL,
				${DatabaseColumns.updatedAt} TEXT NOT NULL
			)
		''');

    await db.execute('''
			CREATE TABLE ${DatabaseTables.transactions} (
				${DatabaseColumns.id} INTEGER PRIMARY KEY AUTOINCREMENT,
				${DatabaseColumns.type} TEXT NOT NULL CHECK (${DatabaseColumns.type} IN ('income', 'expense')),
				${DatabaseColumns.title} TEXT NOT NULL,
				${DatabaseColumns.amount} INTEGER NOT NULL CHECK (${DatabaseColumns.amount} > 0),
				${DatabaseColumns.currency} TEXT NOT NULL DEFAULT '${AppConstants.currencyCode}',
				${DatabaseColumns.transactionDate} TEXT NOT NULL,
				${DatabaseColumns.categoryId} INTEGER NOT NULL,
				${DatabaseColumns.merchantOrSource} TEXT,
				${DatabaseColumns.paymentMethod} TEXT,
				${DatabaseColumns.note} TEXT,
				${DatabaseColumns.receiptPath} TEXT,
				${DatabaseColumns.createdAt} TEXT NOT NULL,
				${DatabaseColumns.updatedAt} TEXT NOT NULL,
				FOREIGN KEY (${DatabaseColumns.categoryId})
					REFERENCES ${DatabaseTables.categories} (${DatabaseColumns.id})
			)
		''');

    await db.execute('''
			CREATE TABLE ${DatabaseTables.budgets} (
				${DatabaseColumns.id} INTEGER PRIMARY KEY AUTOINCREMENT,
				${DatabaseColumns.name} TEXT NOT NULL,
				${DatabaseColumns.amountLimit} INTEGER NOT NULL CHECK (${DatabaseColumns.amountLimit} > 0),
				${DatabaseColumns.categoryId} INTEGER,
				${DatabaseColumns.startDate} TEXT NOT NULL,
				${DatabaseColumns.endDate} TEXT NOT NULL,
				${DatabaseColumns.isArchived} INTEGER NOT NULL DEFAULT 0,
				${DatabaseColumns.createdAt} TEXT NOT NULL,
				${DatabaseColumns.updatedAt} TEXT NOT NULL,
				FOREIGN KEY (${DatabaseColumns.categoryId})
					REFERENCES ${DatabaseTables.categories} (${DatabaseColumns.id})
			)
		''');

    await db.execute(
      'CREATE INDEX idx_transactions_date ON ${DatabaseTables.transactions} (${DatabaseColumns.transactionDate})',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_category ON ${DatabaseTables.transactions} (${DatabaseColumns.categoryId})',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_type ON ${DatabaseTables.transactions} (${DatabaseColumns.type})',
    );
    await db.execute(
      'CREATE INDEX idx_transactions_created ON ${DatabaseTables.transactions} (${DatabaseColumns.createdAt})',
    );

    await _seedCategories(db);
  }

  static Future<void> onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Add future schema migrations here in ascending version order.
  }

  static Future<void> _seedCategories(Database db) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final categories = <Map<String, Object>>[
      ..._categorySeed('expense', [
        ('Food and drinks', 'restaurant', 0xFFE57373),
        ('Transportation', 'directions_car', 0xFF64B5F6),
        ('Shopping', 'shopping_bag', 0xFFBA68C8),
        ('Bills', 'receipt_long', 0xFFFFB74D),
        ('Health', 'health_and_safety', 0xFF81C784),
        ('Education', 'school', 0xFF4DB6AC),
        ('Sports', 'fitness_center', 0xFFFF8A65),
        ('Entertainment', 'movie', 0xFFA1887F),
        ('Family', 'family_restroom', 0xFF7986CB),
        ('Other', 'more_horiz', 0xFF90A4AE),
      ]),
      ..._categorySeed('income', [
        ('Salary', 'payments', 0xFF43A047),
        ('Freelance', 'work', 0xFF00897B),
        ('Business', 'business_center', 0xFF1E88E5),
        ('Investment', 'trending_up', 0xFF7CB342),
        ('Gift', 'card_giftcard', 0xFFD81B60),
        ('Other', 'more_horiz', 0xFF90A4AE),
      ]),
    ];

    final batch = db.batch();
    for (var index = 0; index < categories.length; index++) {
      batch.insert(DatabaseTables.categories, {
        ...categories[index],
        DatabaseColumns.sortOrder: index,
        DatabaseColumns.createdAt: now,
        DatabaseColumns.updatedAt: now,
      });
    }
    await batch.commit(noResult: true);
  }

  static List<Map<String, Object>> _categorySeed(
    String type,
    List<(String, String, int)> values,
  ) {
    return values
        .map(
          (value) => {
            DatabaseColumns.name: value.$1,
            DatabaseColumns.type: type,
            DatabaseColumns.iconKey: value.$2,
            DatabaseColumns.colorValue: value.$3,
            DatabaseColumns.isDefault: 1,
            DatabaseColumns.isFavorite: 0,
            DatabaseColumns.isArchived: 0,
          },
        )
        .toList();
  }
}
