import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();

  // Guardar datos sesión
  static Future<void> saveSessionData(String token, String time) async {
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'last_session_time', value: time);
  }

  // Leer token
  static Future<String?> getToken() async => await _storage.read(key: 'auth_token');

  // Limpiar sesión
  static Future<void> clearSession() async {
    await _storage.delete(key: 'auth_token');
    // Mantenemos el tiempo si quieres auditarlo, o borramos todo
  }
}