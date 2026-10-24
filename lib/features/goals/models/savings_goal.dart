/// Satu tujuan tabungan: nama, ikon emoji, target, dan yang sudah terkumpul.
class SavingsGoal {
  const SavingsGoal({
    this.id,
    required this.name,
    required this.emoji,
    required this.targetAmount,
    this.savedAmount = 0,
    this.targetDate,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String emoji;
  final int targetAmount;
  final int savedAmount;

  /// Tanggal target, opsional.
  final DateTime? targetDate;

  /// Diisi saat terkumpul pertama kali mencapai target (perayaan sekali).
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get progress =>
      targetAmount <= 0 ? 0 : (savedAmount / targetAmount).clamp(0.0, 1.0);

  int get percent =>
      targetAmount <= 0 ? 0 : (savedAmount * 100 / targetAmount).round();

  bool get isReached => targetAmount > 0 && savedAmount >= targetAmount;

  int get remaining => (targetAmount - savedAmount).clamp(0, targetAmount);

  SavingsGoal copyWith({
    int? id,
    String? name,
    String? emoji,
    int? targetAmount,
    int? savedAmount,
    DateTime? targetDate,
    bool clearTargetDate = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? updatedAt,
  }) => SavingsGoal(
    id: id ?? this.id,
    name: name ?? this.name,
    emoji: emoji ?? this.emoji,
    targetAmount: targetAmount ?? this.targetAmount,
    savedAmount: savedAmount ?? this.savedAmount,
    targetDate: clearTargetDate ? null : targetDate ?? this.targetDate,
    completedAt: clearCompletedAt ? null : completedAt ?? this.completedAt,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'emoji': emoji,
    'target_amount': targetAmount,
    'saved_amount': savedAmount,
    'target_date': targetDate == null ? null : _dateKey(targetDate!),
    'completed_at': completedAt?.toUtc().toIso8601String(),
    'created_at': createdAt.toUtc().toIso8601String(),
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };

  factory SavingsGoal.fromMap(Map<String, Object?> map) => SavingsGoal(
    id: map['id'] as int?,
    name: map['name'] as String,
    emoji: map['emoji'] as String,
    targetAmount: map['target_amount'] as int,
    savedAmount: map['saved_amount'] as int? ?? 0,
    targetDate: map['target_date'] == null
        ? null
        : DateTime.parse(map['target_date'] as String),
    completedAt: map['completed_at'] == null
        ? null
        : DateTime.parse(map['completed_at'] as String),
    createdAt: DateTime.parse(map['created_at'] as String),
    updatedAt: DateTime.parse(map['updated_at'] as String),
  );

  static String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
