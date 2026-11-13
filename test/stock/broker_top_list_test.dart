import 'package:dompetku_app/core/theme/app_theme.dart';
import 'package:dompetku_app/features/stock/models/broker_group.dart';
import 'package:dompetku_app/features/stock/models/broker_range_row.dart';
import 'package:dompetku_app/features/stock/widgets/broker_top_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

BrokerRangeRow _row(String code, int value) => BrokerRangeRow(
  ticker: 'BBCA',
  rangeLabel: 'Latest',
  rangeStart: DateTime(2026, 10, 28),
  rangeEnd: DateTime(2026, 10, 28),
  brokerCode: code,
  side: BrokerSide.buy,
  valueIdr: value,
);

void main() {
  testWidgets('label bandar peringkat 6 ke bawah pudar dan diberi keterangan', (
    tester,
  ) async {
    const codes = ['AG', 'AH', 'AI', 'AK', 'AO', 'AZ'];
    final rows = [
      for (final (i, code) in codes.indexed) _row(code, 600000000 - i * 1000),
    ];
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: BrokerTopList(
              side: BrokerSide.buy,
              rows: rows,
              totalCount: rows.length,
              rules: BrokerGroupRules({
                for (final c in codes) c: BrokerGroup.bandar,
              }),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel(RegExp(r'^5\. AO, bandar, ')), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'^6\. AZ, bandar, tidak dihitung di bar')),
      findsOneWidget,
    );
    handle.dispose();
  });
}
