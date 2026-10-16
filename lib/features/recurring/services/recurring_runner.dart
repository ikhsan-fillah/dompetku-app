import '../../../core/constant/domain_enums.dart';
import '../../transaction/models/transaction_model.dart';
import '../../transaction/repositories/transaction_repository.dart';
import '../models/recurring_rule.dart';
import 'recurring_generator.dart';

/// Membuat transaksi untuk tagihan jatuh tempo pada aturan mode auto.
/// Aturan mode ask dilewati sampai Fase E (draft).
class RecurringRunner {
  RecurringRunner({
    required this.rules,
    required this.transactions,
    required this.generator,
    this.drafts,
  });

  final RecurringRuleStore rules;
  final TransactionRepository transactions;
  final RecurringGenerator generator;
  final DraftSink? drafts;

  Future<void> runDue(DateTime today) async {
    for (final rule in await rules.getAll()) {
      final id = rule.id;
      if (id == null) continue;
      for (final due in generator.dueOn(rule, today)) {
        if (rule.mode == RecurringMode.auto) {
          await transactions.insert(_transactionFor(rule, due));
        } else {
          await drafts?.addRecurring(rule, due);
        }
        await rules.markGenerated(id, due);
      }
    }
  }

  TransactionModel _transactionFor(RecurringRule rule, DateTime due) {
    final now = DateTime.now();
    return TransactionModel(
      type: rule.type == RecurringType.income
          ? TransactionType.income
          : TransactionType.expense,
      title: rule.name,
      amount: rule.amount,
      transactionDate: due,
      categoryId: rule.categoryId,
      merchantOrSource: rule.name,
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// Menyimpan tagihan mode ask sebagai draft (dedupe per aturan dan tanggal).
abstract interface class DraftSink {
  Future<void> addRecurring(RecurringRule rule, DateTime due);
}

/// Antarmuka penyimpanan aturan, dipisah agar runner tetap bisa di-test.
abstract interface class RecurringRuleStore {
  Future<List<RecurringRule>> getAll();
  Future<void> markGenerated(int id, DateTime day);
}
