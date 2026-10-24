import '../controllers/recurring_controller.dart';
import '../data/recurring_local_data_source.dart';
import '../models/recurring_rule.dart';
import '../services/recurring_runner.dart';

class RecurringRepositoryImpl implements RecurringRuleStore, RecurringStore {
  RecurringRepositoryImpl(this._dataSource);

  final RecurringLocalDataSource _dataSource;

  @override
  Future<List<RecurringRule>> getAll() => _dataSource.getAll();

  @override
  Future<int> insert(RecurringRule rule) => _dataSource.insert(rule);

  @override
  Future<void> update(RecurringRule rule) => _dataSource.update(rule);

  @override
  Future<void> setActive(int id, bool active) =>
      _dataSource.setActive(id, active);

  @override
  Future<void> markGenerated(int id, DateTime day) =>
      _dataSource.markGenerated(id, day);

  @override
  Future<void> delete(int id) => _dataSource.delete(id);
}
