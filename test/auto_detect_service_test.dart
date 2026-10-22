import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/services/data_refresh_service.dart';
import 'package:dompetku_app/features/autodetect/services/auto_detect_service.dart';
import 'package:dompetku_app/features/autodetect/services/auto_detect_settings.dart';
import 'package:dompetku_app/features/category/models/category_model.dart';
import 'package:dompetku_app/features/category/repositories/category_repository.dart';
import 'package:dompetku_app/features/drafts/models/draft_model.dart';
import 'package:dompetku_app/features/drafts/repositories/draft_repository.dart';
import 'package:dompetku_app/features/transaction/models/transaction_model.dart';
import 'package:dompetku_app/features/transaction/repositories/transaction_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Drafts implements DraftRepository {
  final rows = <DraftModel>[];
  final statuses = <int, DraftStatus>{};

  List<DraftModel> get inserted => rows;

  @override
  Future<void> insertIfNew(DraftModel draft) async {
    if (rows.any((d) => d.dedupeKey == draft.dedupeKey)) return;
    rows.add(
      DraftModel(
        id: rows.length + 1,
        source: draft.source,
        kind: draft.kind,
        amount: draft.amount,
        merchant: draft.merchant,
        detectedAt: draft.detectedAt,
        dedupeKey: draft.dedupeKey,
      ),
    );
  }

  @override
  Future<List<DraftModel>> getPending() async => [
    for (final d in rows)
      if ((statuses[d.id] ?? DraftStatus.pending) == DraftStatus.pending) d,
  ];

  @override
  Future<void> setStatus(int id, DraftStatus status) async =>
      statuses[id] = status;

  @override
  Future<bool> existsNear({
    required String source,
    required int amount,
    required DateTime at,
    required Duration window,
  }) async => rows.any(
    (d) =>
        d.source == source &&
        d.amount == amount &&
        d.detectedAt.difference(at).abs() <= window,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Transactions implements TransactionRepository {
  final saved = <TransactionModel>[];

  @override
  Future<int> insert(TransactionModel transaction) async {
    saved.add(transaction);
    return saved.length;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Categories implements CategoryRepository {
  _Categories(this.items);

  final List<CategoryModel> items;

  @override
  Future<List<CategoryModel>> getAll({bool includeArchived = false}) async =>
      items;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CategoryModel _category(int id, String name, TransactionType type) =>
    CategoryModel(
      id: id,
      name: name,
      type: type,
      iconKey: 'more_horiz',
      colorValue: 0xFF000000,
      isDefault: true,
      isFavorite: false,
      sortOrder: id,
      isArchived: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

class _Settings extends AutoDetectSettings {
  _Settings(this.saveAuto);

  final bool saveAuto;

  @override
  Future<bool> getSaveAuto() async => saveAuto;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('tally/notification_access');
  const bri = 'id.co.bri.brimo';
  const briText =
      'BRImo Sobat BRI! Dana Rp1.500 keluar dari rekening 675301021460535 pada 20/10/2026 16:56:30';
  late _Drafts drafts;
  late _Transactions transactions;
  late AutoDetectService service;

  void mockPending(Object? result) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'drainPending') return result;
          return null;
        });
  }

  Map<String, Object> event(String text, DateTime at, {String pkg = bri}) => {
    'package': pkg,
    'text': text,
    'postTime': at.millisecondsSinceEpoch,
  };

  AutoDetectService build({bool saveAuto = false, List<CategoryModel>? cats}) =>
      AutoDetectService(
        drafts,
        settings: _Settings(saveAuto),
        transactions: transactions,
        categories: _Categories(
          cats ??
              [
                _category(1, 'Shopping', TransactionType.expense),
                _category(2, 'Other', TransactionType.expense),
                _category(3, 'Other', TransactionType.income),
              ],
        ),
      );

  setUp(() {
    drafts = _Drafts();
    transactions = _Transactions();
    service = build();
    Get.put(DataRefreshService());
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    Get.reset();
  });

  test('notifikasi BRI yang masuk saat app tertutup menjadi draft', () async {
    mockPending([event(briText, DateTime(2026, 10, 20, 16, 57))]);
    final before = Get.find<DataRefreshService>().version.value;

    await service.drainPending();

    expect(drafts.inserted, hasLength(1));
    final draft = drafts.inserted.single;
    expect(draft.source, 'BRImo');
    expect(draft.amount, 1500);
    expect(draft.kind, TransactionType.expense);
    expect(transactions.saved, isEmpty);
    expect(Get.find<DataRefreshService>().version.value, before + 1);
  });

  test('antrean kosong tidak menghasilkan draft', () async {
    mockPending(<dynamic>[]);

    await service.drainPending();

    expect(drafts.inserted, isEmpty);
  });

  test('antrean dari app tak dipantau dan teks OTP diabaikan', () async {
    mockPending([
      event('Pembayaran Rp 10.000 ke Toko', DateTime(2026), pkg: 'x.other'),
      event('Kode OTP Anda 123456, jangan bagikan. Rp 10.000', DateTime(2026)),
    ]);

    await service.drainPending();

    expect(drafts.inserted, isEmpty);
  });

  test('channel yang tidak tersedia tidak membuat crash', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          throw PlatformException(code: 'unavailable');
        });

    await service.drainPending();

    expect(drafts.inserted, isEmpty);
  });

  group('dedupe', () {
    test('notifikasi kembar berdekatan hanya jadi satu draft', () async {
      final at = DateTime(2026, 10, 20, 10, 4, 59);
      mockPending([
        event(briText, at),
        event(briText, at.add(const Duration(seconds: 2))),
      ]);

      await service.drainPending();

      expect(drafts.inserted, hasLength(1));
    });

    test('nominal sama yang berjauhan tetap dua draft', () async {
      final at = DateTime(2026, 10, 20, 10, 0);
      mockPending([
        event(briText, at),
        event(briText, at.add(const Duration(minutes: 10))),
      ]);

      await service.drainPending();

      expect(drafts.inserted, hasLength(2));
    });
  });

  group('simpan otomatis', () {
    test('aktif: dicatat ke kategori Other dan draft selesai', () async {
      service = build(saveAuto: true);
      mockPending([event(briText, DateTime(2026, 10, 20, 16, 57))]);

      await service.drainPending();

      expect(transactions.saved, hasLength(1));
      final saved = transactions.saved.single;
      expect(saved.amount, 1500);
      expect(saved.type, TransactionType.expense);
      expect(saved.categoryId, 2);
      expect(saved.merchantOrSource, 'BRImo');
      expect(await drafts.getPending(), isEmpty);
    });

    test('pemasukan masuk ke kategori Other jenis pemasukan', () async {
      service = build(saveAuto: true);
      mockPending([
        event('Dana masuk Rp 25.000 dari Budi', DateTime(2026, 10, 20, 9)),
      ]);

      await service.drainPending();

      expect(transactions.saved.single.type, TransactionType.income);
      expect(transactions.saved.single.categoryId, 3);
    });

    test('nonaktif: hanya draft, tidak ada transaksi', () async {
      mockPending([event(briText, DateTime(2026, 10, 20, 16, 57))]);

      await service.drainPending();

      expect(transactions.saved, isEmpty);
      expect(await drafts.getPending(), hasLength(1));
    });

    test('tanpa kategori yang cocok draft tetap menunggu', () async {
      service = build(saveAuto: true, cats: const []);
      mockPending([event(briText, DateTime(2026, 10, 20, 16, 57))]);

      await service.drainPending();

      expect(transactions.saved, isEmpty);
      expect(await drafts.getPending(), hasLength(1));
    });

    test('notifikasi kembar tidak mencatat transaksi dua kali', () async {
      service = build(saveAuto: true);
      final at = DateTime(2026, 10, 20, 16, 57);
      mockPending([
        event(briText, at),
        event(briText, at.add(const Duration(seconds: 1))),
      ]);

      await service.drainPending();

      expect(transactions.saved, hasLength(1));
    });
  });
}
