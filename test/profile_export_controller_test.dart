import 'package:dompetku_app/core/services/local_data_export_service.dart';
import 'package:dompetku_app/core/services/shared_prefs_service.dart';
import 'package:dompetku_app/features/profile/controllers/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeExportService implements LocalDataExportService {
  _FakeExportService({this.json = '{"app":"DompetKu"}', this.failure});

  final String json;
  final Object? failure;
  int calls = 0;

  @override
  Future<Map<String, Object?>> buildPayload() async => {'app': 'DompetKu'};

  @override
  Future<String> exportJson() async {
    calls++;
    final error = failure;
    if (error != null) throw error;
    return json;
  }
}

void main() {
  test('ekspor berhasil menyalin JSON dan menampilkan status sukses', () async {
    final service = _FakeExportService();
    String? copied;
    final controller = ProfileController(
      SharedPrefsService(),
      exportService: service,
      clipboardWriter: (text) async => copied = text,
    );

    final result = await controller.exportData();

    expect(result, isTrue);
    expect(copied, '{"app":"DompetKu"}');
    expect(controller.exportSuccess.value, isNotNull);
    expect(controller.exportError.value, isNull);
    expect(controller.exportingData.value, isFalse);
    expect(service.calls, 1);
  });

  test('ekspor gagal menampilkan error dan tidak menyalin', () async {
    String? copied;
    final controller = ProfileController(
      SharedPrefsService(),
      exportService: _FakeExportService(failure: StateError('gagal')),
      clipboardWriter: (text) async => copied = text,
    );

    final result = await controller.exportData();

    expect(result, isFalse);
    expect(copied, isNull);
    expect(controller.exportError.value, isNotNull);
    expect(controller.exportSuccess.value, isNull);
    expect(controller.exportingData.value, isFalse);
  });

  test('ekspor tanpa layanan mengembalikan false', () async {
    final controller = ProfileController(SharedPrefsService());

    expect(await controller.exportData(), isFalse);
    expect(controller.exportSuccess.value, isNull);
  });

  test('status ekspor lama dihapus saat ekspor baru dimulai', () async {
    final controller = ProfileController(
      SharedPrefsService(),
      exportService: _FakeExportService(failure: StateError('gagal')),
      clipboardWriter: (text) async {},
    );
    controller.exportSuccess.value = 'lama';

    await controller.exportData();

    expect(controller.exportSuccess.value, isNull);
    expect(controller.exportError.value, isNotNull);
  });
}
