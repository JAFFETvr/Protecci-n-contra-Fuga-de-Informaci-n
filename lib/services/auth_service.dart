/// AuthService - Clase de autenticación simulada
/// Propósito: Demostrar cómo la ofuscación protege la lógica de autenticación.
/// Sin ofuscación, un atacante puede ver nombres como "validateCredentials",
/// "generateToken", "SECRET_SALT", etc. Con ofuscación, estos se renombran a
/// nombres ilegibles como "a", "b", "c".

class AuthService {
  // Singleton pattern
  static final AuthService instance = AuthService._internal();
  factory AuthService() => instance;
  AuthService._internal();

  // ⚠️ DATOS SENSIBLES - visibles sin ofuscación en el APK
  static const String _secretSalt = 'dlp_salt_super_secreto_2024';
  static const String _apiEndpoint = 'https://api.dlpseguro.com/v1/auth';
  static const String _adminToken = 'ADMIN_BYPASS_TOKEN_XYZ987';
  static const int _maxLoginAttempts = 5;
  static const int _sessionDurationMinutes = 30;

  // Usuarios simulados (en producción esto vendría de un servidor)
  final Map<String, String> _credentialsDatabase = {
    'admin@dlp.com': 'hashed_pass_admin_123',
    'usuario@dlp.com': 'hashed_pass_user_456',
    'test@test.com': 'hashed_pass_test_789',
  };

  int _failedAttempts = 0;
  bool _isLocked = false;
  String? _currentToken;
  DateTime? _sessionExpiry;

  /// Valida credenciales y genera token de sesión
  Future<AuthResult> validateCredentials({
    required String email,
    required String password,
  }) async {
    // Simular latencia de red
    await Future.delayed(const Duration(milliseconds: 1200));

    if (_isLocked) {
      return AuthResult.failure('Cuenta bloqueada por múltiples intentos fallidos.');
    }

    // Simular hash de contraseña (en producción usar bcrypt/argon2)
    final hashedPassword = _hashPassword(password);

    if (_credentialsDatabase.containsKey(email) &&
        _credentialsDatabase[email] == hashedPassword) {
      _failedAttempts = 0;
      _currentToken = _generateSessionToken(email);
      _sessionExpiry = DateTime.now().add(
        Duration(minutes: _sessionDurationMinutes),
      );

      return AuthResult.success(
        token: _currentToken!,
        expiresAt: _sessionExpiry!,
        userEmail: email,
      );
    } else {
      _failedAttempts++;
      if (_failedAttempts >= _maxLoginAttempts) {
        _isLocked = true;
        return AuthResult.failure('Cuenta bloqueada: $_maxLoginAttempts intentos fallidos.');
      }
      return AuthResult.failure(
        'Credenciales incorrectas. Intento $_failedAttempts de $_maxLoginAttempts.',
      );
    }
  }

  /// Registra un nuevo usuario con validación
  Future<AuthResult> registerUser({
    required String email,
    required String password,
    required String name,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));

    if (_credentialsDatabase.containsKey(email)) {
      return AuthResult.failure('El correo ya está registrado.');
    }

    final hashedPassword = _hashPassword(password);
    _credentialsDatabase[email] = hashedPassword;

    final token = _generateSessionToken(email);
    _currentToken = token;
    _sessionExpiry = DateTime.now().add(Duration(minutes: _sessionDurationMinutes));

    return AuthResult.success(
      token: token,
      expiresAt: _sessionExpiry!,
      userEmail: email,
    );
  }

  /// Verifica si el token de sesión actual es válido
  bool isSessionValid(String token) {
    if (_currentToken == null || _sessionExpiry == null) return false;
    return token == _currentToken && DateTime.now().isBefore(_sessionExpiry!);
  }

  /// Invalida la sesión actual
  void invalidateSession() {
    _currentToken = null;
    _sessionExpiry = null;
  }

  /// Simula hash de contraseña con salt
  /// ⚠️ Visible sin ofuscación: el atacante ve "_secretSalt" y el algoritmo
  String _hashPassword(String password) {
    final combined = '$password$_secretSalt${_apiEndpoint.length}';
    int hash = 0;
    for (int i = 0; i < combined.length; i++) {
      hash = (hash * 31 + combined.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return 'hashed_${hash.toRadixString(16)}';
  }

  /// Genera token de sesión único
  String _generateSessionToken(String email) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final base = '${email}_${timestamp}_$_secretSalt';
    int hash = 0;
    for (int i = 0; i < base.length; i++) {
      hash = (hash * 37 + base.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return 'dlp_sess_${hash.toRadixString(16)}_$timestamp';
  }

  String get apiEndpoint => _apiEndpoint;
  bool get isAccountLocked => _isLocked;
  int get failedAttempts => _failedAttempts;
}

/// Resultado de operación de autenticación
class AuthResult {
  final bool isSuccess;
  final String? token;
  final DateTime? expiresAt;
  final String? userEmail;
  final String? errorMessage;

  const AuthResult._({
    required this.isSuccess,
    this.token,
    this.expiresAt,
    this.userEmail,
    this.errorMessage,
  });

  factory AuthResult.success({
    required String token,
    required DateTime expiresAt,
    required String userEmail,
  }) {
    return AuthResult._(
      isSuccess: true,
      token: token,
      expiresAt: expiresAt,
      userEmail: userEmail,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(isSuccess: false, errorMessage: message);
  }
}
