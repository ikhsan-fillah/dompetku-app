import 'package:dompetku_app/features/recurring/controllers/recurring_controller.dart';
import 'package:dompetku_app/features/recurring/controllers/recurring_form_controller.dart';
import 'package:dompetku_app/features/recurring/models/recurring_rule.dart';
import 'package:flutter_test/flutter_test.dart';

class _Store implements RecurringStore {
  final List<RecurringRule> inserted = [];
  bool fail = false;

  @override
  Future<List<RecurringRule>> getAll() async => List.of(inserted);

  @override
  Future<int> insert(RecurringRule rule) async {
    if (fail) throw StateError('db');
    inserted.add(rule);
    return inserted.length;
  }

  @override
  Future<void> setActive(int id, bool active) async {}

  @override
  Future<void> delete(int id) async {}

  @override
  Future<void> markGenerated(int id, DateTime day) async {}
}

void main() {
  late _Store store;
  late RecurringFormController form;

  setUp(() {
    store = _Store();
    form = RecurringFormController(store, now: () => DateTime(2026, 9, 10));
  });

  test('nama kosong ditolak', () async {
    form
      ..amountDigits.value = '438000'
      ..categoryId.value = 3;

    expect(await form.save(), isFalse);
    expect(form.error.value, 'Name is required.');
    expect(store.inserted, isEmpty);
  });

  test('nominal nol atau kosong ditolak', () async {
    form
      ..name.value = 'Listrik'
      ..categoryId.value = 3;

    expect(await form.save(), isFalse);
    expect(form.error.value, 'Amount must be more than zero.');
  });

  test('kategori wajib dipilih', () async {
    form
      ..name.value = 'Listrik'
      ..amountDigits.value = '438000';

    expect(await form.save(), isFalse);
    expect(form.error.value, 'Choose a category.');
  });

  test('simpan aturan bulanan dengan tanggal dari hari mulai', () async {
    form
      ..name.value = 'Listrik'
      ..amountDigits.value = '438000'
      ..categoryId.value = 3
      ..frequency.value = RecurringFrequency.monthly
      ..mode.value = RecurringMode.ask;

    expect(await form.save(), isTrue);

    final rule = store.inserted.single;
    expect(rule.name, 'Listrik');
    expect(rule.amount, 438000);
    expect(rule.dayOfMonth, 10);
    expect(rule.startDate, DateTime(2026, 9, 10));
    expect(rule.isActive, isTrue);
  });

  test('simpan aturan mingguan memakai hari dalam minggu', () async {
    form
      ..name.value = 'Laundry'
      ..amountDigits.value = '30000'
      ..categoryId.value = 3
      ..frequency.value = RecurringFrequency.weekly;

    await form.save();

    expect(store.inserted.single.weekday, DateTime(2026, 9, 10).weekday);
    expect(store.inserted.single.dayOfMonth, isNull);
  });

  test('kegagalan penyimpanan menampilkan pesan dan tidak lolos', () async {
    store.fail = true;
    form
      ..name.value = 'Listrik'
      ..amountDigits.value = '438000'
      ..categoryId.value = 3;

    expect(await form.save(), isFalse);
    expect(form.error.value, 'Failed to save. Try again.');
  });
}
