import '../../../core/constant/domain_enums.dart';

enum DraftStatus { pending, confirmed, dismissed }

class DraftModel {
  const DraftModel({
    this.id,
    required this.source,
    required this.kind,
    required this.amount,
    this.merchant,
    this.categoryId,
    this.paymentMethod,
    required this.detectedAt,
    this.status = DraftStatus.pending,
    required this.dedupeKey,
    this.needsReview = false,
    this.recurringRuleId,
  });

  final int? id;
  final String source;
  final TransactionType kind;
  final int amount;
  final String? merchant;
  final int? categoryId;
  final PaymentMethod? paymentMethod;
  final DateTime detectedAt;
  final DraftStatus status;
  final String dedupeKey;
  final bool needsReview;
  final int? recurringRuleId;

  DraftModel copyWith({int? amount, String? merchant}) => DraftModel(
    id: id,
    source: source,
    kind: kind,
    amount: amount ?? this.amount,
    merchant: merchant ?? this.merchant,
    categoryId: categoryId,
    paymentMethod: paymentMethod,
    detectedAt: detectedAt,
    status: status,
    dedupeKey: dedupeKey,
    needsReview: needsReview,
    recurringRuleId: recurringRuleId,
  );
}
