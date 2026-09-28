import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/database/database_constants.dart';

class CategoryModel {
  const CategoryModel({
    this.id,
    required this.name,
    required this.type,
    required this.iconKey,
    required this.colorValue,
    required this.isDefault,
    required this.isFavorite,
    required this.sortOrder,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final TransactionType type;
  final String iconKey;
  final int colorValue;
  final bool isDefault;
  final bool isFavorite;
  final int sortOrder;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CategoryModel.fromMap(Map<String, Object?> map) {
    return CategoryModel(
      id: map[DatabaseColumns.id] as int?,
      name: map[DatabaseColumns.name] as String,
      type: TransactionType.values.byName(map[DatabaseColumns.type] as String),
      iconKey: map[DatabaseColumns.iconKey] as String,
      colorValue: map[DatabaseColumns.colorValue] as int,
      isDefault: (map[DatabaseColumns.isDefault] as int) == 1,
      isFavorite: (map[DatabaseColumns.isFavorite] as int) == 1,
      sortOrder: map[DatabaseColumns.sortOrder] as int,
      isArchived: (map[DatabaseColumns.isArchived] as int) == 1,
      createdAt: DateTime.parse(map[DatabaseColumns.createdAt] as String),
      updatedAt: DateTime.parse(map[DatabaseColumns.updatedAt] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) DatabaseColumns.id: id,
      DatabaseColumns.name: name,
      DatabaseColumns.type: type.name,
      DatabaseColumns.iconKey: iconKey,
      DatabaseColumns.colorValue: colorValue,
      DatabaseColumns.isDefault: isDefault ? 1 : 0,
      DatabaseColumns.isFavorite: isFavorite ? 1 : 0,
      DatabaseColumns.sortOrder: sortOrder,
      DatabaseColumns.isArchived: isArchived ? 1 : 0,
      DatabaseColumns.createdAt: createdAt.toUtc().toIso8601String(),
      DatabaseColumns.updatedAt: updatedAt.toUtc().toIso8601String(),
    };
  }
}
