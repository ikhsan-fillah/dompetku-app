import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/secure_storage_service.dart';

/// Login ke akun Supabase satu pengguna untuk modul saham.
abstract interface class StockAuth {
  /// False bila URL atau publishable key belum diberikan lewat `--dart-define`.
  bool get isConfigured;

  /// Email akun yang sedang masuk, null bila belum masuk.
  String? get email;

  /// Memulihkan sesi tersimpan. True bila pengguna sudah masuk.
  Future<bool> restoreSession();

  /// Masuk dengan email dan password. Password tidak disimpan di perangkat;
  /// yang disimpan hanya sesi (token) di secure storage.
  Future<void> signIn({required String email, required String password});

  Future<void> signOut();
}

/// Gagal masuk atau gagal menghubungi Supabase, dengan pesan yang aman
/// ditampilkan.
class StockAuthException implements Exception {
  const StockAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Menyimpan sesi Supabase di flutter_secure_storage, bukan SharedPreferences
/// bawaan supabase_flutter, karena sesi berisi refresh token.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage(this._storage);

  static const sessionKey = 'stock_supabase_session';

  final SecureStorageService _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async =>
      (await _storage.read(sessionKey)) != null;

  @override
  Future<String?> accessToken() => _storage.read(sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: sessionKey, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(sessionKey);
}

/// Implementasi nyata di atas supabase_flutter. Supabase baru diinisialisasi
/// saat modul saham dibuka, jadi app tetap tanpa jaringan bila modul tidak
/// dipakai.
class SupabaseStockAuth implements StockAuth {
  SupabaseStockAuth(this._secureStorage);

  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  final SecureStorageService _secureStorage;
  Future<void>? _initialization;

  @override
  bool get isConfigured => _url.isNotEmpty && _publishableKey.isNotEmpty;

  /// Klien yang sudah siap dipakai; hanya valid setelah [restoreSession] atau
  /// [signIn] selesai.
  SupabaseClient get client => Supabase.instance.client;

  @override
  String? get email => isConfigured && _initialization != null
      ? client.auth.currentUser?.email
      : null;

  Future<void> _ensureInitialized() => _initialization ??= Supabase.initialize(
    url: _url,
    publishableKey: _publishableKey,
    authOptions: FlutterAuthClientOptions(
      localStorage: SecureSessionStorage(_secureStorage),
      detectSessionInUri: false,
    ),
  ).then((_) {});

  @override
  Future<bool> restoreSession() async {
    await _ensureInitialized();
    return client.auth.currentSession != null;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _ensureInitialized();
    try {
      await client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (error) {
      throw StockAuthException(error.message);
    }
  }

  @override
  Future<void> signOut() async {
    await _ensureInitialized();
    await client.auth.signOut();
  }
}
