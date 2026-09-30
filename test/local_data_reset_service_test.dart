import 'package:dompetku_app/core/database/app_database.dart';
import 'package:dompetku_app/core/services/local_data_reset_service.dart';
import 'package:dompetku_app/core/services/secure_storage_service.dart';
import 'package:dompetku_app/core/services/shared_prefs_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAppDatabase extends AppDatabase {
  _FakeAppDatabase(this.events);

  final List<String> events;
  bool fail = false;

  @override
  Future<void> deleteDatabaseFile() async {
    events.add('database');
    if (fail) throw StateError('database failed');
  }
}

class _FakeSharedPrefsService extends SharedPrefsService {
  _FakeSharedPrefsService(this.events);

  final List<String> events;
  bool fail = false;

  @override
  Future<void> clearAll() async {
    events.add('preferences');
    if (fail) throw StateError('preferences failed');
  }
}

class _FakeSecureStorage extends SecureStorageService {
  _FakeSecureStorage(this.events);

  final List<String> events;
  bool fail = false;

  @override
  Future<void> deleteAll() async {
    events.add('secureStorage');
    if (fail) throw StateError('secure storage failed');
  }
}

void main() {
  test('resetAll menghapus database, preferensi, dan secure storage', () async {
    final events = <String>[];
    final service = LocalDataResetService(
      _FakeAppDatabase(events),
      _FakeSharedPrefsService(events),
      _FakeSecureStorage(events),
    );

    await service.resetAll();

    expect(events, ['database', 'preferences', 'secureStorage']);
  });

  test('resetAll berhenti bila penghapusan database gagal', () async {
    final events = <String>[];
    final database = _FakeAppDatabase(events)..fail = true;
    final service = LocalDataResetService(
      database,
      _FakeSharedPrefsService(events),
      _FakeSecureStorage(events),
    );

    await expectLater(service.resetAll(), throwsStateError);

    expect(events, ['database']);
  });
}
