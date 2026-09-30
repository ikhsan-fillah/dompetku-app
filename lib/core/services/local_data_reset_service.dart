import '../database/app_database.dart';
import 'secure_storage_service.dart';
import 'shared_prefs_service.dart';

class LocalDataResetService {
  LocalDataResetService(
    this._database,
    this._preferences,
    this._secureStorage,
  );

  final AppDatabase _database;
  final SharedPrefsService _preferences;
  final SecureStorageService _secureStorage;

  Future<void> resetAll() async {
    await _database.deleteDatabaseFile();
    await _preferences.clearAll();
    await _secureStorage.deleteAll();
  }
}
