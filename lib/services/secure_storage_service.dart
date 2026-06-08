import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredSession {
  final String token;
  final DateTime closedAt;

  StoredSession({required this.token, required this.closedAt});
}

class SecureStorageService {
  static final SecureStorageService instance = SecureStorageService._internal();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  factory SecureStorageService() {
    return instance;
  }

  SecureStorageService._internal();

  // Inicializa el almacenamiento seguro con datos de prueba
  Future<void> initializeSensitiveData() async {
    print('🔑 Inicializando datos sensibles en almacenamiento seguro...');
    await _storage.write(key: 'ine_data', value: 'INE_FOTO_Y_SERIE_XYZ123');
    await _storage.write(key: 'payment_card_token', value: 'tok_mercado_pago_987654321');
    await _storage.write(key: 'kyc_biometric_data', value: 'hash_selfie_liveness_abc987');
    await _storage.write(key: 'api_keys', value: 'apikey_mercado_pago_secreta_000');
    print('✅ Datos sensibles almacenados con éxito.');
  }

  // Realiza el Remote Wipe eliminando todos los datos sensibles
  Future<void> wipeData() async {
    print('🚨 ALERTA: Iniciando Wipe Remoto (DLP)...');
    await _storage.deleteAll();
    print('💥 WIPE COMPLETADO: Todos los datos sensibles han sido eliminados del dispositivo.');
  }

  // Método auxiliar para verificar los datos (solo para pruebas)
  Future<void> printCurrentData() async {
    Map<String, String> allValues = await _storage.readAll();
    print('📊 Estado actual del Secure Storage: $allValues');
  }

  // =========================================================
  // MÉTODOS DE SESIÓN ANTIGUOS RESTAURADOS
  // =========================================================

  Future<void> saveSession({
    required String token,
    required DateTime closedAt,
  }) async {
    await _storage.write(key: 'session_token', value: token);
    await _storage.write(
      key: 'session_closed_at',
      value: closedAt.toIso8601String(),
    );
  }

  Future<StoredSession?> readSession() async {
    final token = await _storage.read(key: 'session_token');
    final closedAtStr = await _storage.read(key: 'session_closed_at');

    if (token != null && closedAtStr != null) {
      return StoredSession(
        token: token,
        closedAt: DateTime.parse(closedAtStr),
      );
    }
    return null;
  }

  Future<void> clearSession() async {
    await _storage.delete(key: 'session_token');
    await _storage.delete(key: 'session_closed_at');
  }
}
