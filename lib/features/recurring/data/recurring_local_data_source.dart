import 'package:dompetku_app/core/database/app_database.dart';
import 'package:dompetku_app/core/database/database_constants.dart';

import '../models/recurring_rule.dart';

class RecurringLocalDataSource {
  RecurringLocalDataSource(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<List<RecurringRule>> getAll() async {
    final database = await _appDatabase.database;
    final rows = await database.query(
      DatabaseTables.recurringRules,
      orderBy: '${DatabaseColumns.isActive} DESC, ${DatabaseColumns.id} ASC',
    );
    return rows.map(_fromMap).toList();
  }

  Future<int> insert(RecurringRule rule) async {
    final database = await _appDatabase.database;
    return database.insert(DatabaseTables.recurringRules, _toMap(rule));
  }

  Future<void> setActive(int id, bool active) async {
    final database = await _appDatabase.database;
    await database.update(
      DatabaseTables.recurringRules,
      {
        DatabaseColumns.isActive: active ? 1 : 0,
        DatabaseColumns.updatedAt: DateTime.now().toUtc().toIso8601String(),
      },
      where: '${DatabaseColumns.id} = ?',
      whereArgs: [id],
    );
  }

  Future<void> markGenerated(int id, DateTime day) async {
    final database = await _appDatabase.database;
    await database.update(
      DatabaseTables.recurringRules,
      {DatabaseColumns.lastGeneratedOn: _dateKey(day)},
      where: '${DatabaseColumns.id} = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) async {
    final database = await _appDatabase.database;
    await database.delete(
      DatabaseTables.recurringRules,
      where: '${DatabaseColumns.id} = ?',
      whereArgs: [id],
    );
  }

  Map<String, Object?> _toMap(RecurringRule rule) => {
    if (rule.id != null) DatabaseColumns.id: rule.id,
    DatabaseColumns.name: rule.name,
    DatabaseColumns.type: rule.type.name,
    DatabaseColumns.categoryId: rule.categoryId,
    DatabaseColumns.amount: rule.amount,
    'frequency': rule.frequency.name,
    'day_of_month': rule.dayOfMonth,
    'weekday': rule.weekday,
    DatabaseColumns.startDate: _dateKey(rule.startDate),
    'mode': rule.mode.name,
    DatabaseColumns.isActive: rule.isActive ? 1 : 0,
    DatabaseColumns.lastGeneratedOn: rule.lastGeneratedOn == null
        ? null
        : _dateKey(rule.lastGeneratedOn!),
    DatabaseColumns.createdAt: rule.createdAt.toUtc().toIso8601String(),
    DatabaseColumns.updatedAt: rule.updatedAt.toUtc().toIso8601String(),
  };

  RecurringRule _fromMap(Map<String, Object?> map) => RecurringRule(
    id: map[DatabaseColumns.id] as int,
    name: map[DatabaseColumns.name] as String,
    type: RecurringType.values.byName(map[DatabaseColumns.type] as String),
    categoryId: map[DatabaseColumns.categoryId] as int,
    amount: map[DatabaseColumns.amount] as int,
    frequency: RecurringFrequency.values.byName(map['frequency'] as String),
    dayOfMonth: map['day_of_month'] as int?,
    weekday: map['weekday'] as int?,
    startDate: _parseDate(map[DatabaseColumns.startDate] as String),
    mode: RecurringMode.values.byName(map['mode'] as String),
    isActive: (map[DatabaseColumns.isActive] as int) == 1,
    lastGeneratedOn: map[DatabaseColumns.lastGeneratedOn] == null
        ? null
        : _parseDate(map[DatabaseColumns.lastGeneratedOn] as String),
    createdAt: DateTime.parse(map[DatabaseColumns.createdAt] as String),
    updatedAt: DateTime.parse(map[DatabaseColumns.updatedAt] as String),
  );

  String _dateKey(DateTime value) {
    final local = DateTime(value.year, value.month, value.day);
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  DateTime _parseDate(String value) => DateTime.parse(value);
}
