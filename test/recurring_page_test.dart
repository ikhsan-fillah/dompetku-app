import 'package:dompetku_app/features/recurring/controllers/recurring_controller.dart';
import 'package:dompetku_app/features/recurring/models/recurring_rule.dart';
import 'package:dompetku_app/features/recurring/pages/recurring_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

RecurringRule _rule({int id = 1, bool active = true}) => RecurringRule(
  id: id,
  name: 'Listrik',
  type: RecurringType.expense,
  categoryId: 1,
  amount: 438000,
  frequency: RecurringFrequency.monthly,
  dayOfMonth: 5,
  startDate: DateTime(2026, 9, 5),
  mode: RecurringMode.ask,
  isActive: active,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

class _Store implements RecurringStore {
  _Store(this.items);

  List<RecurringRule> items;
  final toggled = <int, bool>{};

  @override
  Future<List<RecurringRule>> getAll() async => List.of(items);

  @override
  Future<void> setActive(int id, bool active) async {
    toggled[id] = active;
  }

  @override
  Future<int> insert(RecurringRule rule) async => 1;

  @override
  Future<void> delete(int id) async {}

  @override
  Future<void> markGenerated(int id, DateTime day) async {}
}

Future<void> _open(WidgetTester tester, _Store store) async {
  Get.put<RecurringController>(RecurringController(store));
  await tester.pumpWidget(const GetMaterialApp(home: RecurringPage()));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(Get.reset);

  testWidgets('daftar kosong menampilkan ajakan menambah', (tester) async {
    await _open(tester, _Store([]));

    expect(
      find.text('No recurring items yet. Add rent, subscriptions, or bills.'),
      findsOneWidget,
    );
  });

  testWidgets('menampilkan item dengan nominal dan jadwal', (tester) async {
    await _open(tester, _Store([_rule()]));

    expect(find.text('Listrik'), findsOneWidget);
    expect(find.text('Rp 438.000'), findsOneWidget);
    expect(
      find.text('Monthly · due 5th · Ask me first'),
      findsOneWidget,
    );
  });

  testWidgets('sakelar menonaktifkan tanpa menghapus item', (tester) async {
    final store = _Store([_rule()]);
    await _open(tester, store);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(store.toggled[1], isFalse);
    expect(find.text('Listrik'), findsOneWidget);
  });
}
