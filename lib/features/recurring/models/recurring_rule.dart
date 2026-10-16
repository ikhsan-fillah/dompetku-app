enum RecurringType { income, expense }

enum RecurringFrequency { weekly, monthly, yearly }

enum RecurringMode { ask, auto }

class RecurringRule {
  const RecurringRule({
    this.id,
    required this.name,
    required this.type,
    required this.categoryId,
    required this.amount,
    required this.frequency,
    this.dayOfMonth,
    this.weekday,
    required this.startDate,
    required this.mode,
    required this.isActive,
    this.lastGeneratedOn,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final RecurringType type;
  final int categoryId;
  final int amount;
  final RecurringFrequency frequency;
  final int? dayOfMonth;
  final int? weekday;
  final DateTime startDate;
  final RecurringMode mode;
  final bool isActive;
  final DateTime? lastGeneratedOn;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecurringRule withLastGenerated(DateTime day) => RecurringRule(
    id: id,
    name: name,
    type: type,
    categoryId: categoryId,
    amount: amount,
    frequency: frequency,
    dayOfMonth: dayOfMonth,
    weekday: weekday,
    startDate: startDate,
    mode: mode,
    isActive: isActive,
    lastGeneratedOn: day,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
