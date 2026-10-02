import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/utils/date_range.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/dashboard/models/spending_trend_point.dart';
import 'package:dompetku_app/features/dashboard/services/dashboard_insights_service.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime(2026, 9, 29);
const _service = DashboardInsightsService();

CategoryModel _cat(
  int id,
  String name, {
  bool favorite = false,
  bool archived = false,
  TransactionType type = TransactionType.expense,
}) {
  return CategoryModel(
    id: id,
    name: name,
    type: type,
    iconKey: 'restaurant',
    colorValue: 0xFFE57373,
    isDefault: false,
    isFavorite: favorite,
    sortOrder: id,
    isArchived: archived,
    createdAt: _now,
    updatedAt: _now,
  );
}

TransactionModel _tx(int id, int categoryId, int amount, DateTime date) {
  return TransactionModel(
    id: id,
    type: TransactionType.expense,
    title: 'T$id',
    amount: amount,
    transactionDate: date,
    categoryId: categoryId,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  group('favoriteCards', () {
    test(
      'favorit lebih dulu lalu diisi kategori dengan pengeluaran terbesar',
      () {
        final cards = _service.favoriteCards(
          totals: {2: 500, 3: 900, 4: 100, 5: 300},
          categories: [
            _cat(1, 'A', favorite: true),
            _cat(2, 'B'),
            _cat(3, 'C'),
            _cat(4, 'D'),
            _cat(5, 'E'),
          ],
        );
        expect(cards.map((c) => c.categoryId).toList(), [1, 3, 2, 5]);
        expect(cards.first.amount, 0);
      },
    );

    test('kategori arsip dan pemasukan tidak dipakai', () {
      final cards = _service.favoriteCards(
        totals: {1: 100, 2: 200},
        categories: [
          _cat(1, 'Arsip', favorite: true, archived: true),
          _cat(2, 'Gaji', type: TransactionType.income),
          _cat(3, 'Aktif'),
        ],
      );
      expect(cards, isEmpty);
    });

    test('persentase bagian dihitung terhadap total pengeluaran', () {
      final cards = _service.favoriteCards(
        totals: {1: 250, 2: 750},
        categories: [_cat(1, 'A'), _cat(2, 'B')],
      );
      expect(cards.first.categoryId, 2);
      expect(cards.first.sharePercent, 75);
    });
  });

  group('recentTransactions', () {
    test('terbaru dulu, dibatasi, dan memakai nama kategori', () {
      final range = DateRange(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 29),
      );
      final items = _service.recentTransactions(
        transactions: [
          _tx(1, 1, 10, DateTime(2026, 9, 1)),
          _tx(2, 1, 20, DateTime(2026, 9, 5)),
          _tx(3, 2, 30, DateTime(2026, 9, 9)),
          _tx(4, 2, 40, DateTime(2026, 9, 12)),
          _tx(5, 1, 50, DateTime(2026, 9, 20)),
          _tx(6, 1, 60, DateTime(2026, 8, 20)),
        ],
        categories: [_cat(1, 'Makanan'), _cat(2, 'Belanja')],
        range: range,
      );
      expect(items.map((i) => i.id).toList(), [5, 4, 3, 2]);
      expect(items.first.categoryName, 'Makanan');
      expect(items[1].categoryName, 'Belanja');
    });
  });

  group('spendingInsight', () {
    test('menyebut kategori dengan kenaikan terbesar', () {
      final insight = _service.spendingInsight(
        current: {1: 1180, 2: 1050},
        previous: {1: 1000, 2: 1000},
        categories: [_cat(1, 'Makanan'), _cat(2, 'Belanja')],
      );
      expect(insight, isNotNull);
      expect(insight!.message, contains('Makanan'));
      expect(insight.message, contains('18%'));
    });

    test('tanpa kenaikan berarti tidak ada insight', () {
      final insight = _service.spendingInsight(
        current: {1: 900},
        previous: {1: 1000},
        categories: [_cat(1, 'Makanan')],
      );
      expect(insight, isNull);
    });
  });

  group('trendBuckets', () {
    test('satu bulan menjadi 15 batang dengan label tanggal ganjil', () {
      final range = DateRange(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 29),
      );
      final points = [
        for (var day = 1; day <= 29; day++)
          SpendingTrendPoint(date: DateTime(2026, 9, day), amount: 100),
      ];
      final buckets = _service.trendBuckets(points: points, range: range);
      expect(buckets.length, 15);
      expect(buckets.first.label, '1');
      expect(buckets.last.label, '29');
      expect(buckets.first.amount, 200);
      expect(buckets.last.amount, 100);
      expect(buckets.fold<int>(0, (sum, b) => sum + b.amount), 2900);
    });

    test('tanpa data menghasilkan daftar kosong', () {
      final range = DateRange(
        start: DateTime(2026, 9, 1),
        end: DateTime(2026, 9, 29),
      );
      expect(_service.trendBuckets(points: const [], range: range), isEmpty);
    });
  });
}
