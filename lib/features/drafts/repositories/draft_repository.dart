import '../../../core/constant/domain_enums.dart';
import '../../recurring/models/recurring_rule.dart';
import '../../recurring/services/recurring_runner.dart';
import '../data/draft_local_data_source.dart';
import '../models/draft_model.dart';

abstract interface class DraftRepository {
  Future<List<DraftModel>> getPending();
  Future<int> countPending();
  Future<void> insertIfNew(DraftModel draft);
  Future<void> update(DraftModel draft);
  Future<void> setStatus(int id, DraftStatus status);
}

class RecurringDraftSink implements DraftSink {
  RecurringDraftSink(this._drafts);

  final DraftRepository _drafts;

  @override
  Future<void> addRecurring(RecurringRule rule, DateTime due) {
    final ruleId = rule.id;
    return _drafts.insertIfNew(
      DraftModel(
        source: 'Recurring',
        kind: rule.type == RecurringType.income
            ? TransactionType.income
            : TransactionType.expense,
        amount: rule.amount,
        merchant: rule.name,
        categoryId: rule.categoryId,
        detectedAt: due,
        dedupeKey: 'recurring:$ruleId:${due.year}-${due.month}-${due.day}',
        recurringRuleId: ruleId,
      ),
    );
  }
}

class DraftRepositoryImpl implements DraftRepository {
  DraftRepositoryImpl(this._dataSource);

  final DraftLocalDataSource _dataSource;

  @override
  Future<List<DraftModel>> getPending() => _dataSource.getPending();

  @override
  Future<int> countPending() => _dataSource.countPending();

  @override
  Future<void> insertIfNew(DraftModel draft) => _dataSource.insertIfNew(draft);

  @override
  Future<void> update(DraftModel draft) => _dataSource.update(draft);

  @override
  Future<void> setStatus(int id, DraftStatus status) =>
      _dataSource.setStatus(id, status);
}
