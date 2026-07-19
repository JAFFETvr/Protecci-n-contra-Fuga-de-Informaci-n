import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/sensitive_data_processor.dart';
import '../services/network_service.dart';

/// SecurityDemoScreen - Pantalla de demostración de clases sensibles
/// Muestra en tiempo real el uso de AuthService y SensitiveDataProcessor.
/// Útil para la actividad: demuestra qué información queda expuesta sin ofuscación.
class SecurityDemoScreen extends StatefulWidget {
  const SecurityDemoScreen({super.key});

  @override
  State<SecurityDemoScreen> createState() => _SecurityDemoScreenState();
}

class _SecurityDemoScreenState extends State<SecurityDemoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo de Seguridad'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF7B61FF),
          labelColor: const Color(0xFF7B61FF),
          unselectedLabelColor: const Color(0xFF777777),
          tabs: const [
            Tab(icon: Icon(Icons.person_rounded), text: 'Autenticación'),
            Tab(icon: Icon(Icons.credit_card_rounded), text: 'Datos Sensibles'),
            Tab(icon: Icon(Icons.https_rounded), text: 'SSL Pinning'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AuthDemoTab(),
          _SensitiveDataTab(),
          _SslPinningTab(),
        ],
      ),
    );
  }
}

// ─── TAB 1: Demostración de AuthService ──────────────────────────────────────

class _AuthDemoTab extends StatefulWidget {
  const _AuthDemoTab();

  @override
  State<_AuthDemoTab> createState() => _AuthDemoTabState();
}

class _AuthDemoTabState extends State<_AuthDemoTab> {
  final _emailCtrl = TextEditingController(text: 'usuario@dlp.com');
  final _passCtrl = TextEditingController(text: 'mi_contrasena');
  bool _isLoading = false;
  String _result = '';
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _testLogin() async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    final result = await AuthService.instance.validateCredentials(
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
    );

    setState(() {
      _isLoading = false;
      _isSuccess = result.isSuccess;
      if (result.isSuccess) {
        _result = '✅ Login exitoso\n'
            'Token: ${result.token?.substring(0, 20)}...\n'
            'Expira: ${result.expiresAt?.toLocal().toString().split('.')[0]}\n'
            'Usuario: ${result.userEmail}';
      } else {
        _result = '❌ Error: ${result.errorMessage}\n'
            'Intentos fallidos: ${AuthService.instance.failedAttempts}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF7B61FF).withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF7B61FF).withAlpha(60)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF7B61FF), size: 16),
                  SizedBox(width: 8),
                  Text('Clase: AuthService', style: TextStyle(color: Color(0xFF7B61FF), fontSize: 13, fontWeight: FontWeight.bold)),
                ]),
                SizedBox(height: 6),
                Text(
                  'Sin ofuscación, en JADX se verían: _secretSalt, _adminToken, validateCredentials(), _hashPassword(), _generateSessionToken()',
                  style: TextStyle(color: Color(0xFF999999), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Usuarios de prueba:', style: TextStyle(color: Color(0xFF777777), fontSize: 12)),
          const SizedBox(height: 6),
          _credentialHint('admin@dlp.com', 'cualquier_pass'),
          _credentialHint('usuario@dlp.com', 'cualquier_pass'),
          const SizedBox(height: 20),
          TextFormField(
            controller: _emailCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF555555), size: 18),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passCtrl,
            obscureText: true,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: Icon(Icons.lock_outline_rounded, color: Color(0xFF555555), size: 18),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _testLogin,
              icon: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.login_rounded),
              label: Text(_isLoading ? 'Autenticando...' : 'Probar Autenticación'),
            ),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isSuccess
                    ? const Color(0xFF00C853).withAlpha(20)
                    : const Color(0xFFFF4757).withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isSuccess
                      ? const Color(0xFF00C853).withAlpha(60)
                      : const Color(0xFFFF4757).withAlpha(60),
                ),
              ),
              child: Text(
                _result,
                style: TextStyle(
                  color: _isSuccess ? const Color(0xFF00C853) : const Color(0xFFFF4757),
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Estado del servicio
          _ServiceInfoCard(
            title: 'Estado de AuthService',
            items: [
              ('Endpoint API', AuthService.instance.apiEndpoint),
              ('Cuenta bloqueada', AuthService.instance.isAccountLocked ? 'SÍ 🔒' : 'No'),
              ('Intentos fallidos', '${AuthService.instance.failedAttempts}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _credentialHint(String email, String note) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '• $email ($note)',
        style: const TextStyle(color: Color(0xFF555555), fontSize: 11, fontFamily: 'monospace'),
      ),
    );
  }
}

// ─── TAB 2: Demostración de SensitiveDataProcessor ───────────────────────────

class _SensitiveDataTab extends StatefulWidget {
  const _SensitiveDataTab();

  @override
  State<_SensitiveDataTab> createState() => _SensitiveDataTabState();
}

class _SensitiveDataTabState extends State<_SensitiveDataTab> {
  bool _isProcessing = false;
  String _paymentResult = '';
  String _kycResult = '';
  String _encryptResult = '';

  Future<void> _testPayment() async {
    setState(() { _isProcessing = true; _paymentResult = ''; });

    final result = await SensitiveDataProcessor.instance.processPaymentCard(
      cardNumber: '4532 0151 1283 0366',
      expiryDate: '12/26',
      cvv: '123',
      holderName: 'Juan Pérez',
    );

    setState(() {
      _isProcessing = false;
      if (result.isSuccess) {
        _paymentResult = '✅ Tarjeta procesada\n'
            'Token: ${result.token?.substring(0, 25)}...\n'
            'Enmascarada: ${result.maskedCard}\n'
            'Riesgo: ${result.riskLevel?.name.toUpperCase()}';
      } else {
        _paymentResult = '❌ ${result.errorMessage}';
      }
    });
  }

  Future<void> _testKyc() async {
    setState(() { _kycResult = ''; });

    final result = await SensitiveDataProcessor.instance.processIdentityDocument(
      documentType: 'INE',
      documentNumber: '123456789012345678',
      dateOfBirth: '1990-05-15',
      fullName: 'Juan Carlos Pérez López',
    );

    setState(() {
      if (result.isSuccess) {
        _kycResult = '✅ KYC verificado\n'
            'ID: ${result.verificationId}\n'
            'Hash biométrico: ${result.biometricHash?.substring(0, 20)}...\n'
            'Nivel KYC: ${result.kycLevel}';
      } else {
        _kycResult = '❌ ${result.errorMessage}';
      }
    });
  }

  void _testEncryption() {
    const plaintext = 'datos_secretos_del_usuario_123';
    final encrypted = SensitiveDataProcessor.instance.encryptSensitiveData(plaintext);
    setState(() {
      _encryptResult = 'Original: $plaintext\nCifrado: $encrypted';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFF4757).withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFF4757).withAlpha(60)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFFF4757), size: 16),
                  SizedBox(width: 8),
                  Text('Clase: SensitiveDataProcessor', style: TextStyle(color: Color(0xFFFF4757), fontSize: 13, fontWeight: FontWeight.bold)),
                ]),
                SizedBox(height: 6),
                Text(
                  'Sin ofuscación, son visibles: _encryptionKey, _paymentApiKey, _kycServiceUrl, _highRiskThreshold, algoritmo Luhn, lógica KYC',
                  style: TextStyle(color: Color(0xFF999999), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Botón tarjeta de crédito
          _ActionButton(
            icon: Icons.credit_card_rounded,
            label: 'Procesar Tarjeta (Luhn + Token)',
            color: const Color(0xFF00D4FF),
            isLoading: _isProcessing,
            onPressed: _testPayment,
          ),
          if (_paymentResult.isNotEmpty) _ResultBox(_paymentResult),
          const SizedBox(height: 12),

          // Botón KYC
          _ActionButton(
            icon: Icons.badge_rounded,
            label: 'Verificar Identidad (KYC)',
            color: const Color(0xFFFFB300),
            isLoading: false,
            onPressed: _testKyc,
          ),
          if (_kycResult.isNotEmpty) _ResultBox(_kycResult),
          const SizedBox(height: 12),

          // Botón cifrado
          _ActionButton(
            icon: Icons.enhanced_encryption_rounded,
            label: 'Cifrar Datos (XOR + Key)',
            color: const Color(0xFF00C853),
            isLoading: false,
            onPressed: _testEncryption,
          ),
          if (_encryptResult.isNotEmpty) _ResultBox(_encryptResult),
          const SizedBox(height: 20),

          // Info del procesador
          _ServiceInfoCard(
            title: 'Configuración de SensitiveDataProcessor',
            items: [
              ('Gateway de Pagos', SensitiveDataProcessor.instance.paymentGatewayUrl),
              ('Servicio KYC', SensitiveDataProcessor.instance.kycServiceUrl),
              ('Versión Política DLP', SensitiveDataProcessor.instance.dlpPolicyVersion),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── TAB 3: Demostración de SSL/TLS Pinning ──────────────────────────────────

class _SslPinningTab extends StatefulWidget {
  const _SslPinningTab();

  @override
  State<_SslPinningTab> createState() => _SslPinningTabState();
}

class _SslPinningTabState extends State<_SslPinningTab> {
  bool _pinningEnabled = true;
  bool _isLoading = false;
  String _result = '';
  bool _isSuccess = false;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _result = '';
    });

    try {
      await NetworkService.instance.configure(pinningEnabled: _pinningEnabled);
      final response = await NetworkService.instance.getSecure('/todos/1');
      setState(() {
        _isSuccess = true;
        _result = '✅ Conexión exitosa (HTTP ${response.statusCode})\n'
            'Certificado del servidor validado correctamente.\n'
            'Respuesta: ${response.data}';
      });
    } on SslPinningException catch (e) {
      setState(() {
        _isSuccess = false;
        _result = '🚨 ${e.message}';
      });
    } catch (e) {
      setState(() {
        _isSuccess = false;
        _result = '❌ Error de red: $e';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF00D4FF).withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF00D4FF).withAlpha(60)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.https_rounded, color: Color(0xFF00D4FF), size: 16),
                  SizedBox(width: 8),
                  Text('Clase: NetworkService', style: TextStyle(color: Color(0xFF00D4FF), fontSize: 13, fontWeight: FontWeight.bold)),
                ]),
                SizedBox(height: 6),
                Text(
                  'Con pinning activo, la app solo confía en el certificado de '
                  'jsonplaceholder.typicode.com almacenado localmente. Un proxy '
                  'MitM (Charles, HTTP Toolkit, ZAP) que intercepte el tráfico será '
                  'rechazado aunque su CA esté instalada como confiable en el dispositivo.',
                  style: TextStyle(color: Color(0xFF999999), fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: SwitchListTile(
              value: _pinningEnabled,
              onChanged: _isLoading ? null : (v) => setState(() => _pinningEnabled = v),
              activeThumbColor: const Color(0xFF00C853),
              title: const Text('SSL Pinning activo', style: TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: Text(
                _pinningEnabled
                    ? 'Solo se confía en el certificado pineado'
                    : 'Vulnerable: confía en el almacén del sistema (permite MitM)',
                style: const TextStyle(color: Color(0xFF777777), fontSize: 11),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _testConnection,
              icon: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.wifi_tethering_rounded),
              label: Text(_isLoading ? 'Conectando...' : 'Probar Conexión Segura'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D4FF),
                foregroundColor: Colors.black,
              ),
            ),
          ),
          if (_result.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _isSuccess
                    ? const Color(0xFF00C853).withAlpha(20)
                    : const Color(0xFFFF4757).withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isSuccess
                      ? const Color(0xFF00C853).withAlpha(60)
                      : const Color(0xFFFF4757).withAlpha(60),
                ),
              ),
              child: Text(
                _result,
                style: TextStyle(
                  color: _isSuccess ? const Color(0xFF00C853) : const Color(0xFFFF4757),
                  fontSize: 13,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Prueba de Concepto (PoC): configura un proxy (Charles / HTTP Toolkit / '
            'OWASP ZAP) en el dispositivo e instala su CA como confiable. Con el '
            'switch desactivado, el proxy podrá leer las peticiones. Con el switch '
            'activado, el handshake TLS debe fallar y verás el error controlado arriba.',
            style: TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

// ─── Widgets auxiliares ───────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}

class _ResultBox extends StatelessWidget {
  final String text;
  const _ResultBox(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Color(0xFF00D4FF), fontSize: 12, fontFamily: 'monospace'),
        ),
      ),
    );
  }
}

class _ServiceInfoCard extends StatelessWidget {
  final String title;
  final List<(String, String)> items;

  const _ServiceInfoCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFF777777), fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item.$1}: ', style: const TextStyle(color: Color(0xFF555555), fontSize: 11)),
                Expanded(
                  child: Text(
                    item.$2,
                    style: const TextStyle(color: Color(0xFF00C853), fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
