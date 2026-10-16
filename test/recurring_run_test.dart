import 'package:dompetku_app/features/recurring/models/recurring_rule.dart';
import 'package:dompetku_app/features/recurring/services/recurring_generator.dart';
import 'package:dompetku_app/features/recurring/services/recurring_runner.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Rules implements RecurringRuleStore {
  final List<RecurringRule> items = [];
  final Map<int, DateTime> generated = {};

  @override
  Future<List<RecurringRule>> getAll() async => List.of(items);

  @override
  Future<void> markGenerated(int id, DateTime day) async {
    generated[id] = day;
    final index = items.indexWhere((rule) => rule.id == id);
    if (index == -1) return;
    final rule = items[index];
    items[index] = rule.withLastGenerated(day);
  }
}

class _Transactions implements TransactionRepository {
  final List<TransactionModel> inserted = [];

  @override
  Future<int> insert(TransactionModel transaction) async {
    inserted.add(transaction);
    return inserted.length;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

RecurringRule _auto({int id = 1}) => RecurringRule(
  id: id,
  name: 'Listrik',
  type: RecurringType.expense,
  categoryId: 3,
  amount: 438000,
  frequency: RecurringFrequency.monthly,
  dayOfMonth: 5,
  startDate: DateTime(2026, 9, 5),
  mode: RecurringMode.auto,
  isActive: true,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  _askRunnerTest();
  test('aturan auto membuat transaksi sekali per tagihan', () async {
    final rules = _Rules()..items.add(_auto());
    final transactions = _Transactions();
    final runner = RecurringRunner(
      rules: rules,
      transactions: transactions,
      generator: const RecurringGenerator(),
    );

    await runner.runDue(DateTime(2026, 9, 6));
    await runner.runDue(DateTime(2026, 9, 6));

    expect(transactions.inserted.length, 1);
    expect(transactions.inserted.first.amount, 438000);
    expect(transactions.inserted.first.categoryId, 3);
    expect(transactions.inserted.first.transactionDate, DateTime(2026, 9, 5));
    expect(rules.generated[1], DateTime(2026, 9, 5));
  });

  test('aturan ask tidak membuat transaksi langsung', () async {
    final rules = _Rules()
      ..items.add(
        RecurringRule(
          id: 2,
          name: 'Langganan',
          type: RecurringType.expense,
          categoryId: 3,
          amount: 50000,
          frequency: RecurringFrequency.monthly,
          dayOfMonth: 5,
          startDate: DateTime(2026, 9, 5),
          mode: RecurringMode.ask,
          isActive: true,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
    final transactions = _Transactions();
    final runner = RecurringRunner(
      rules: rules,
      transactions: transactions,
      generator: const RecurringGenerator(),
    );

    await runner.runDue(DateTime(2026, 9, 6));

    expect(transactions.inserted, isEmpty);
  });

  test('tagihan bulan 31 hari tidak menghasilkan duplikat', () async {
    final rules = _Rules()
      ..items.add(
        _auto().copyWithStart(DateTime(2026, 1, 31), day: 31),
      );
    final transactions = _Transactions();
    final runner = RecurringRunner(
      rules: rules,
      transactions: transactions,
      generator: const RecurringGenerator(),
    );

    await runner.runDue(DateTime(2026, 4, 30));
    await runner.runDue(DateTime(2026, 4, 30));

    expect(transactions.inserted.length, 4);
  });
}

extension on RecurringRule {
  RecurringRule copyWithStart(DateTime start, {required int day}) {
    return RecurringRule(
      id: id,
      name: name,
      type: type,
      categoryId: categoryId,
      amount: amount,
      frequency: frequency,
      dayOfMonth: day,
      startDate: start,
      mode: RecurringMode.auto,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class _Sink implements DraftSink {
  final List<DateTime> dues = [];

  @override
  Future<void> addRecurring(RecurringRule rule, DateTime due) async {
    dues.add(due);
  }
}

void _askRunnerTest() {
  test('aturan ask dikirim sebagai draft, bukan transaksi', () async {
    final rules = _Rules()
      ..items.add(
        RecurringRule(
          id: 5,
          name: 'Langganan',
          type: RecurringType.expense,
          categoryId: 3,
          amount: 50000,
          frequency: RecurringFrequency.monthly,
          dayOfMonth: 5,
          startDate: DateTime(2026, 9, 5),
          mode: RecurringMode.ask,
          isActive: true,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );
    final transactions = _Transactions();
    final sink = _Sink();
    final runner = RecurringRunner(
      rules: rules,
      transactions: transactions,
      generator: const RecurringGenerator(),
      drafts: sink,
    );

    await runner.runDue(DateTime(2026, 9, 6));
    await runner.runDue(DateTime(2026, 9, 6));

    expect(transactions.inserted, isEmpty);
    expect(sink.dues, [DateTime(2026, 9, 5)]);
  });
}
