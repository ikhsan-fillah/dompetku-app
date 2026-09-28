import 'package:dompetku_app/core/database/database_constants.dart';

class BudgetModel {
  const BudgetModel({
    this.id,
    required this.name,
    required this.amountLimit,
    this.categoryId,
    required this.startDate,
    required this.endDate,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final int amountLimit;
  final int? categoryId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory BudgetModel.fromMap(Map<String, Object?> map) {
    return BudgetModel(
      id: map[DatabaseColumns.id] as int?,
      name: map[DatabaseColumns.name] as String,
      amountLimit: map[DatabaseColumns.amountLimit] as int,
      categoryId: map[DatabaseColumns.categoryId] as int?,
      startDate: DateTime.parse(map[DatabaseColumns.startDate] as String),
      endDate: DateTime.parse(map[DatabaseColumns.endDate] as String),
      isArchived: (map[DatabaseColumns.isArchived] as int) == 1,
      createdAt: DateTime.parse(map[DatabaseColumns.createdAt] as String),
      updatedAt: DateTime.parse(map[DatabaseColumns.updatedAt] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) DatabaseColumns.id: id,
      DatabaseColumns.name: name,
      DatabaseColumns.amountLimit: amountLimit,
      DatabaseColumns.categoryId: categoryId,
      DatabaseColumns.startDate: startDate.toUtc().toIso8601String(),
      DatabaseColumns.endDate: endDate.toUtc().toIso8601String(),
      DatabaseColumns.isArchived: isArchived ? 1 : 0,
      DatabaseColumns.createdAt: createdAt.toUtc().toIso8601String(),
      DatabaseColumns.updatedAt: updatedAt.toUtc().toIso8601String(),
    };
  }
}
