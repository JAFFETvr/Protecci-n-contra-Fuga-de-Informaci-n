import 'dart:convert';

/// SensitiveDataProcessor - Clase que procesa información sensible
/// Propósito: Demostrar la exposición de lógica de negocio crítica sin ofuscación.
/// Un atacante con JADX puede ver: claves de cifrado, algoritmos, endpoints,
/// lógica de validación de tarjetas, procesamiento de datos PII, etc.

class SensitiveDataProcessor {
  static final SensitiveDataProcessor instance = SensitiveDataProcessor._internal();
  factory SensitiveDataProcessor() => instance;
  SensitiveDataProcessor._internal();

  // ⚠️ CLAVES Y CONFIGURACIÓN CRÍTICA - expuesta sin ofuscación
  static const String _encryptionKey = 'AES256_KEY_DLP_SEGURO_2024_XYZ!!';
  static const String _paymentGatewayUrl = 'https://pagos.dlpseguro.com/api/v2';
  static const String _paymentApiKey = 'pk_live_51HxYz_mercadopago_secret';
  static const String _kycServiceUrl = 'https://kyc.biometrics.dlp.com/verify';
  static const String _dlpPolicyVersion = '2.4.1';

  // Umbrales de riesgo (lógica de negocio visible sin ofuscación)
  static const double _highRiskThreshold = 10000.0;
  static const double _mediumRiskThreshold = 5000.0;
  static const int _maxDailyTransactions = 20;

  /// Procesa y "cifra" datos de tarjeta de crédito (simulado)
  /// ⚠️ Sin ofuscación: el atacante ve el algoritmo completo de tokenización
  Future<PaymentTokenResult> processPaymentCard({
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String holderName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    // Validar número de tarjeta con algoritmo de Luhn
    if (!_validateLuhn(cardNumber.replaceAll(' ', ''))) {
      return PaymentTokenResult.failure('Número de tarjeta inválido.');
    }

    // Tokenizar datos sensibles (simulado)
    final cardData = {
      'number': _maskCardNumber(cardNumber),
      'expiry': expiryDate,
      'holder': holderName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    final token = _generatePaymentToken(cardData);
    final riskLevel = _assessTransactionRisk(double.parse(
      cardNumber.replaceAll(' ', '').substring(0, 4),
    ));

    return PaymentTokenResult.success(
      token: token,
      maskedCard: _maskCardNumber(cardNumber),
      riskLevel: riskLevel,
    );
  }

  /// Procesa datos de identidad (KYC - Know Your Customer)
  Future<KycResult> processIdentityDocument({
    required String documentType,
    required String documentNumber,
    required String dateOfBirth,
    required String fullName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    // Validar formato de CURP/INE mexicana (simulado)
    if (!_validateMexicanDocument(documentType, documentNumber)) {
      return KycResult.failure('Documento de identidad inválido.');
    }

    final biometricHash = _generateBiometricHash(
      name: fullName,
      document: documentNumber,
      dob: dateOfBirth,
    );

    return KycResult.success(
      verificationId: 'KYC_${DateTime.now().millisecondsSinceEpoch}',
      biometricHash: biometricHash,
      kycLevel: _determinKycLevel(documentType),
    );
  }

  /// Evalúa el nivel de riesgo de una transacción
  /// ⚠️ Sin ofuscación: el atacante ve los umbrales exactos y puede evadir controles
  RiskLevel _assessTransactionRisk(double amount) {
    if (amount >= _highRiskThreshold) return RiskLevel.high;
    if (amount >= _mediumRiskThreshold) return RiskLevel.medium;
    return RiskLevel.low;
  }

  /// Algoritmo de Luhn para validar tarjetas de crédito
  bool _validateLuhn(String cardNumber) {
    int sum = 0;
    bool alternate = false;
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);
      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      alternate = !alternate;
    }
    return sum % 10 == 0;
  }

  /// Genera token de pago único
  String _generatePaymentToken(Map<String, dynamic> cardData) {
    final jsonStr = jsonEncode(cardData);
    final keyedData = '$jsonStr$_encryptionKey$_paymentApiKey';
    int hash = 0;
    for (int i = 0; i < keyedData.length; i++) {
      hash = (hash * 31 + keyedData.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return 'tok_${hash.toRadixString(16)}_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Enmascara número de tarjeta (muestra solo últimos 4 dígitos)
  String _maskCardNumber(String cardNumber) {
    final clean = cardNumber.replaceAll(' ', '');
    if (clean.length < 4) return '****';
    return '**** **** **** ${clean.substring(clean.length - 4)}';
  }

  /// Genera hash biométrico simulado
  String _generateBiometricHash({
    required String name,
    required String document,
    required String dob,
  }) {
    final combined = '$name|$document|$dob|$_encryptionKey';
    int hash = 0;
    for (int i = 0; i < combined.length; i++) {
      hash = (hash * 41 + combined.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return 'biometric_${hash.toRadixString(16)}';
  }

  /// Valida documentos mexicanos (CURP/INE simulado)
  bool _validateMexicanDocument(String type, String number) {
    if (type == 'CURP') {
      return RegExp(r'^[A-Z]{4}[0-9]{6}[HM][A-Z]{5}[0-9A-Z]{2}$')
          .hasMatch(number.toUpperCase());
    } else if (type == 'INE') {
      return number.length == 18 && RegExp(r'^[0-9]+$').hasMatch(number);
    }
    return number.length >= 6;
  }

  /// Determina el nivel KYC basado en el tipo de documento
  int _determinKycLevel(String documentType) {
    switch (documentType) {
      case 'INE': return 3;
      case 'CURP': return 2;
      case 'PASSPORT': return 3;
      default: return 1;
    }
  }

  /// Cifra texto con XOR simulado usando la clave privada
  /// ⚠️ Sin ofuscación: la clave "_encryptionKey" es visible directamente
  String encryptSensitiveData(String plaintext) {
    final keyBytes = _encryptionKey.codeUnits;
    final plainBytes = plaintext.codeUnits;
    final encrypted = List<int>.generate(
      plainBytes.length,
      (i) => plainBytes[i] ^ keyBytes[i % keyBytes.length],
    );
    return base64Encode(encrypted);
  }

  String get paymentGatewayUrl => _paymentGatewayUrl;
  String get kycServiceUrl => _kycServiceUrl;
  String get dlpPolicyVersion => _dlpPolicyVersion;
}

// ─── Modelos de resultado ─────────────────────────────────────────────────────

enum RiskLevel { low, medium, high }

class PaymentTokenResult {
  final bool isSuccess;
  final String? token;
  final String? maskedCard;
  final RiskLevel? riskLevel;
  final String? errorMessage;

  const PaymentTokenResult._({
    required this.isSuccess,
    this.token,
    this.maskedCard,
    this.riskLevel,
    this.errorMessage,
  });

  factory PaymentTokenResult.success({
    required String token,
    required String maskedCard,
    required RiskLevel riskLevel,
  }) {
    return PaymentTokenResult._(
      isSuccess: true,
      token: token,
      maskedCard: maskedCard,
      riskLevel: riskLevel,
    );
  }

  factory PaymentTokenResult.failure(String message) {
    return PaymentTokenResult._(isSuccess: false, errorMessage: message);
  }
}

class KycResult {
  final bool isSuccess;
  final String? verificationId;
  final String? biometricHash;
  final int? kycLevel;
  final String? errorMessage;

  const KycResult._({
    required this.isSuccess,
    this.verificationId,
    this.biometricHash,
    this.kycLevel,
    this.errorMessage,
  });

  factory KycResult.success({
    required String verificationId,
    required String biometricHash,
    required int kycLevel,
  }) {
    return KycResult._(
      isSuccess: true,
      verificationId: verificationId,
      biometricHash: biometricHash,
      kycLevel: kycLevel,
    );
  }

  factory KycResult.failure(String message) {
    return KycResult._(isSuccess: false, errorMessage: message);
  }
}
