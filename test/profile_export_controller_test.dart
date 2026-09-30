import 'package:dompetku_app/core/services/local_data_export_service.dart';
import 'package:dompetku_app/core/services/local_export_file_service.dart';
import 'package:dompetku_app/core/services/shared_prefs_service.dart';
import 'package:dompetku_app/features/profile/controllers/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeExportService implements LocalDataExportService {
  _FakeExportService({this.failure});

  static const json = '{"app":"DompetKu"}';
  final Object? failure;
  int calls = 0;

  @override
  Future<Map<String, Object?>> buildPayload({DateTime? exportedAt}) async => {
    'app': 'DompetKu',
  };

  @override
  Future<String> exportJson() async {
    calls++;
    final error = failure;
    if (error != null) throw error;
    return json;
  }

  @override
  Future<LocalDataExport> createExport() async {
    calls++;
    final error = failure;
    if (error != null) throw error;
    return LocalDataExport(
      json: json,
      exportedAt: DateTime.utc(2026, 9, 30, 8),
    );
  }
}

class _FakeExportFileService implements LocalExportFileService {
  String? sharedJson;
  DateTime? sharedAt;

  @override
  Future<LocalExportFileResult> shareJson(
    String json, {
    required DateTime exportedAt,
  }) async {
    sharedJson = json;
    sharedAt = exportedAt;
    return const LocalExportFileResult(
      fileName: 'dompetku-export-20260930-080000.json',
    );
  }
}

void main() {
  test(
    'ekspor berhasil membagikan berkas JSON dan menampilkan status sukses',
    () async {
      final service = _FakeExportService();
      final fileService = _FakeExportFileService();
      final controller = ProfileController(
        SharedPrefsService(),
        exportService: service,
        exportFileService: fileService,
      );

      final result = await controller.exportData();

      expect(result, isTrue);
      expect(fileService.sharedJson, '{"app":"DompetKu"}');
      expect(fileService.sharedAt, DateTime.utc(2026, 9, 30, 8));
      expect(
        controller.exportSuccess.value,
        contains('dompetku-export-20260930-080000.json'),
      );
      expect(controller.exportSuccess.value, isNotNull);
      expect(controller.exportError.value, isNull);
      expect(controller.exportingData.value, isFalse);
      expect(service.calls, 1);
    },
  );

  test('ekspor gagal menampilkan error dan tidak menyalin', () async {
    final controller = ProfileController(
      SharedPrefsService(),
      exportService: _FakeExportService(failure: StateError('gagal')),
      exportFileService: _FakeExportFileService(),
    );

    final result = await controller.exportData();

    expect(result, isFalse);
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
      exportFileService: _FakeExportFileService(),
    );
    controller.exportSuccess.value = 'lama';

    await controller.exportData();

    expect(controller.exportSuccess.value, isNull);
    expect(controller.exportError.value, isNotNull);
  });
}
