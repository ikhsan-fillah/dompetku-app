import 'package:dompetku_app/core/constant/app_constant.dart';
import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/database/database_constants.dart';

class TransactionModel {
  const TransactionModel({
    this.id,
    required this.type,
    required this.title,
    required this.amount,
    this.currency = AppConstants.currencyCode,
    required this.transactionDate,
    required this.categoryId,
    this.merchantOrSource,
    this.paymentMethod,
    this.note,
    this.receiptPath,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final TransactionType type;
  final String title;
  final int amount;
  final String currency;
  final DateTime transactionDate;
  final int categoryId;
  final String? merchantOrSource;
  final PaymentMethod? paymentMethod;
  final String? note;
  final String? receiptPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory TransactionModel.fromMap(Map<String, Object?> map) {
    final paymentMethodValue = map[DatabaseColumns.paymentMethod] as String?;
    return TransactionModel(
      id: map[DatabaseColumns.id] as int?,
      type: TransactionType.values.byName(map[DatabaseColumns.type] as String),
      title: map[DatabaseColumns.title] as String,
      amount: map[DatabaseColumns.amount] as int,
      currency: map[DatabaseColumns.currency] as String,
      transactionDate: DateTime.parse(
        map[DatabaseColumns.transactionDate] as String,
      ),
      categoryId: map[DatabaseColumns.categoryId] as int,
      merchantOrSource: map[DatabaseColumns.merchantOrSource] as String?,
      paymentMethod: paymentMethodValue == null
          ? null
          : PaymentMethod.values.byName(paymentMethodValue),
      note: map[DatabaseColumns.note] as String?,
      receiptPath: map[DatabaseColumns.receiptPath] as String?,
      createdAt: DateTime.parse(map[DatabaseColumns.createdAt] as String),
      updatedAt: DateTime.parse(map[DatabaseColumns.updatedAt] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) DatabaseColumns.id: id,
      DatabaseColumns.type: type.name,
      DatabaseColumns.title: title,
      DatabaseColumns.amount: amount,
      DatabaseColumns.currency: currency,
      DatabaseColumns.transactionDate: transactionDate
          .toUtc()
          .toIso8601String(),
      DatabaseColumns.categoryId: categoryId,
      DatabaseColumns.merchantOrSource: merchantOrSource,
      DatabaseColumns.paymentMethod: paymentMethod?.name,
      DatabaseColumns.note: note,
      DatabaseColumns.receiptPath: receiptPath,
      DatabaseColumns.createdAt: createdAt.toUtc().toIso8601String(),
      DatabaseColumns.updatedAt: updatedAt.toUtc().toIso8601String(),
    };
  }
}
