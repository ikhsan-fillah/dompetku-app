import 'package:dompetku_app/core/constant/domain_enums.dart';
import 'package:dompetku_app/core/services/data_refresh_service.dart';
import 'package:dompetku_app/features/autodetect/services/auto_detect_service.dart';
import 'package:dompetku_app/features/drafts/models/draft_model.dart';
import 'package:dompetku_app/features/drafts/repositories/draft_repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

class _Drafts implements DraftRepository {
  final inserted = <DraftModel>[];

  @override
  Future<void> insertIfNew(DraftModel draft) async => inserted.add(draft);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('tally/notification_access');
  late _Drafts drafts;
  late AutoDetectService service;

  void mockPending(Object? result) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'drainPending') return result;
          return null;
        });
  }

  setUp(() {
    drafts = _Drafts();
    service = AutoDetectService(drafts);
    Get.put(DataRefreshService());
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    Get.reset();
  });

  test('notifikasi BRI yang masuk saat app tertutup menjadi draft', () async {
    mockPending([
      {
        'package': 'id.co.bri.brimo',
        'text':
            'BRImo Sobat BRI! Dana Rp1.500 keluar dari rekening 675301021460535 pada 20/10/2026 16:56:30',
        'postTime': DateTime(2026, 10, 20, 16, 57).millisecondsSinceEpoch,
      },
    ]);
    final before = Get.find<DataRefreshService>().version.value;

    await service.drainPending();

    expect(drafts.inserted, hasLength(1));
    final draft = drafts.inserted.single;
    expect(draft.source, 'BRImo');
    expect(draft.amount, 1500);
    expect(draft.kind, TransactionType.expense);
    expect(Get.find<DataRefreshService>().version.value, before + 1);
  });

  test('antrean kosong tidak menghasilkan draft', () async {
    mockPending(<dynamic>[]);

    await service.drainPending();

    expect(drafts.inserted, isEmpty);
  });

  test('antrean dari app tak dipantau dan teks OTP diabaikan', () async {
    mockPending([
      {
        'package': 'com.example.other',
        'text': 'Pembayaran Rp 10.000 ke Toko',
        'postTime': 1,
      },
      {
        'package': 'id.co.bri.brimo',
        'text': 'Kode OTP Anda 123456, jangan bagikan. Rp 10.000',
        'postTime': 2,
      },
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
}
