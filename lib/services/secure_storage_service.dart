import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class _Keys {
  static const sessionToken = 'session_token';
  static const sessionClosedAt = 'session_closed_at';
}

class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  final _storage = const FlutterSecureStorage(
    iOptions: _iosOptions,
    aOptions: _androidOptions,
  );

  Future<void> saveSession({
    required String token,
    required DateTime closedAt,
  }) async {
    await Future.wait([
      _storage.write(
        key: _Keys.sessionToken,
        value: token,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      ),
      _storage.write(
        key: _Keys.sessionClosedAt,
        value: closedAt.toIso8601String(),
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      ),
    ]);
  }

  Future<StoredSession?> readSession() async {
    final results = await Future.wait([
      _storage.read(
        key: _Keys.sessionToken,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      ),
      _storage.read(
        key: _Keys.sessionClosedAt,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      ),
    ]);

    final token = results[0];
    final closedAtStr = results[1];

    if (token == null || closedAtStr == null) return null;

    return StoredSession(
      token: token,
      closedAt: DateTime.parse(closedAtStr),
    );
  }

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(
        key: _Keys.sessionToken,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      ),
      _storage.delete(
        key: _Keys.sessionClosedAt,
        iOptions: _iosOptions,
        aOptions: _androidOptions,
      ),
    ]);
  }
}

class StoredSession {
  final String token;
  final DateTime closedAt;

  const StoredSession({required this.token, required this.closedAt});

  @override
  String toString() =>
      'StoredSession(token: $token, closedAt: ${closedAt.toIso8601String()})';
}
