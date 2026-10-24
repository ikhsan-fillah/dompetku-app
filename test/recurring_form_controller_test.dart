import 'package:dompetku_app/features/recurring/controllers/recurring_controller.dart';
import 'package:dompetku_app/features/recurring/controllers/recurring_form_controller.dart';
import 'package:dompetku_app/features/recurring/models/recurring_rule.dart';
import 'package:flutter_test/flutter_test.dart';

class _Store implements RecurringStore {
  final List<RecurringRule> inserted = [];
  final List<RecurringRule> updated = [];
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

  @override
  Future<void> update(RecurringRule rule) async {
    if (fail) throw StateError('db');
    updated.add(rule);
  }
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
    expect(form.error.value, 'Nama wajib diisi.');
    expect(store.inserted, isEmpty);
  });

  test('nominal nol atau kosong ditolak', () async {
    form
      ..name.value = 'Listrik'
      ..categoryId.value = 3;

    expect(await form.save(), isFalse);
    expect(form.error.value, 'Nominal harus lebih dari nol.');
  });

  test('kategori wajib dipilih', () async {
    form
      ..name.value = 'Listrik'
      ..amountDigits.value = '438000';

    expect(await form.save(), isFalse);
    expect(form.error.value, 'Pilih kategori.');
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
    expect(form.error.value, 'Gagal menyimpan. Coba lagi.');
  });

  test('startEdit lalu save memperbarui aturan, bukan menambah', () async {
    final original = RecurringRule(
      id: 7,
      name: 'Spotify',
      type: RecurringType.expense,
      categoryId: 3,
      amount: 55000,
      frequency: RecurringFrequency.monthly,
      dayOfMonth: 5,
      startDate: DateTime(2026, 9, 5),
      mode: RecurringMode.ask,
      isActive: false,
      lastGeneratedOn: DateTime(2026, 9, 5),
      createdAt: DateTime.utc(2026, 9, 1),
      updatedAt: DateTime.utc(2026, 9, 1),
    );
    form.startEdit(original);
    expect(form.isEditing, isTrue);
    expect(form.amountDigits.value, '55000');

    form.amountDigits.value = '60000';
    final ok = await form.save();

    expect(ok, isTrue);
    expect(store.inserted, isEmpty);
    final saved = store.updated.single;
    expect(saved.id, 7);
    expect(saved.amount, 60000);
    expect(saved.isActive, isFalse);
    expect(saved.lastGeneratedOn, DateTime(2026, 9, 5));
    expect(saved.createdAt, DateTime.utc(2026, 9, 1));
  });

  test('startNew mengosongkan form setelah edit', () {
    form.name.value = 'Lama';
    form.amountDigits.value = '1000';
    form.startNew();

    expect(form.isEditing, isFalse);
    expect(form.name.value, '');
    expect(form.amountDigits.value, '');
  });
}
