import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Excepción específica para fallos de validación de certificado.
/// Permite distinguirla de errores de red genéricos (timeout, sin conexión, etc.)
/// y mostrar en la UI un mensaje controlado en lugar de un stacktrace crudo.
class SslPinningException implements Exception {
  final String message;
  SslPinningException(this.message);

  @override
  String toString() => message;
}

/// NetworkService - Cliente HTTP con SSL/TLS Pinning
///
/// Certificado pineado extraído con:
///   openssl s_client -connect jsonplaceholder.typicode.com:443
///     -servername jsonplaceholder.typicode.com -showcerts
///     `| openssl x509 -outform PEM > assets/certs/jsonplaceholder.pem`
///
/// El pinning se implementa con un SecurityContext que IGNORA el almacén de
/// confianza del sistema operativo (withTrustedRoots: false) y solo confía en
/// el certificado del .pem. Esto es crítico: proxies de intercepción como
/// Charles Proxy o HTTP Toolkit funcionan instalando su propia CA como
/// confiable en el dispositivo de pruebas. Si solo se usara
/// `badCertificateCallback` sobre un HttpClient normal, esa validación nunca
/// se dispararía (el sistema ya confía en el proxy) y el pinning no
/// detectaría el ataque. Con el SecurityContext acotado, cualquier
/// certificado que no sea exactamente el pineado hace fallar el handshake.
class NetworkService {
  static final NetworkService instance = NetworkService._internal();
  factory NetworkService() => instance;
  NetworkService._internal();

  static const String baseUrl = 'https://jsonplaceholder.typicode.com';
  static const String _pinnedCertAsset = 'assets/certs/jsonplaceholder.pem';

  final Dio _dio = Dio(BaseOptions(baseUrl: baseUrl));
  bool _pinningEnabled = true;

  bool get pinningEnabled => _pinningEnabled;

  /// Configura el cliente HTTP.
  ///
  /// [pinningEnabled] = false reproduce el comportamiento vulnerable. OJO:
  /// dart:io no usa el almacén de certificados del sistema operativo (ni los
  /// certificados "de usuario" que instales manualmente en Android/iOS para
  /// proxies como Charles/HTTP Toolkit) — usa una lista de CAs raíz
  /// compilada en el engine de Flutter. Por eso un `HttpClient()` normal ya
  /// rechazaría por sí solo el certificado de un proxy MitM, sin que eso
  /// tenga nada que ver con pinning. Para que el PoC sea realista (una app
  /// sin protección que SÍ es interceptable), este modo acepta explícitamente
  /// cualquier certificado — el patrón exacto que causa esta vulnerabilidad
  /// en apps reales (`badCertificateCallback = (c, h, p) => true` puesto por
  /// error, normalmente para "arreglar" errores de SSL en desarrollo).
  Future<void> configure({required bool pinningEnabled}) async {
    _pinningEnabled = pinningEnabled;

    // El certificado se carga aquí (async) porque CreateHttpClient exige un
    // closure síncrono; los bytes ya cargados quedan capturados por él.
    final certBytes = pinningEnabled
        ? (await rootBundle.load(_pinnedCertAsset)).buffer.asUint8List()
        : null;

    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      if (certBytes == null) {
        final client = HttpClient();
        client.badCertificateCallback = (cert, host, port) => true;
        return client;
      }

      final context = SecurityContext(withTrustedRoots: false)
        ..setTrustedCertificatesBytes(certBytes);

      final client = HttpClient(context: context);
      // Red de seguridad explícita: cualquier certificado que llegue aquí no
      // coincide con nuestro contexto acotado -> se rechaza siempre.
      client.badCertificateCallback = (cert, host, port) => false;
      return client;
    };
  }

  /// Petición GET protegida. Lanza [SslPinningException] cuando el
  /// certificado del servidor no coincide con el pineado.
  Future<Response> getSecure(String path) async {
    try {
      return await _dio.get(path);
    } on DioException catch (e) {
      final isCertError = e.type == DioExceptionType.badCertificate ||
          e.error is HandshakeException;
      if (isCertError) {
        throw SslPinningException(
          'Conexión insegura detectada: el certificado del servidor no '
          'coincide con el certificado esperado. Posible ataque MitM.',
        );
      }
      rethrow;
    }
  }
}
