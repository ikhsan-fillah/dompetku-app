import '../data/recurring_local_data_source.dart';
import '../models/recurring_rule.dart';

class RecurringRepositoryImpl {
  RecurringRepositoryImpl(this._dataSource);

  final RecurringLocalDataSource _dataSource;

  Future<List<RecurringRule>> getAll() => _dataSource.getAll();

  Future<int> insert(RecurringRule rule) => _dataSource.insert(rule);

  Future<void> setActive(int id, bool active) =>
      _dataSource.setActive(id, active);

  Future<void> markGenerated(int id, DateTime day) =>
      _dataSource.markGenerated(id, day);

  Future<void> delete(int id) => _dataSource.delete(id);
}
