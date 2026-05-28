import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  
  // Canal de comunicación con Android
  static const platform = MethodChannel('com.example.mi_app_dlp/security');

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    
    // Activar protección contra captura de pantalla al entrar
    _setSecureFlag(true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    // Desactivar protección contra captura de pantalla al salir
    _setSecureFlag(false);
    super.dispose();
  }

  Future<void> _setSecureFlag(bool secure) async {
    try {
      await platform.invokeMethod('setSecureFlag', {'secure': secure});
    } catch (e) {
      print('Error al establecer FLAG_SECURE: $e');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    // Simulated authentication delay
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48),
                      _buildLogo(),
                      const SizedBox(height: 48),
                      _buildEmailField(),
                      const SizedBox(height: 16),
                      _buildPasswordField(),
                      const SizedBox(height: 32),
                      _buildLoginButton(),
                      const SizedBox(height: 28),
                      _buildDivider(),
                      const SizedBox(height: 28),
                      _buildRegisterLink(),
                      const SizedBox(height: 32),
                      _buildSecurityNote(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF7B61FF).withAlpha(26),
            border: Border.all(
              color: const Color(0xFF7B61FF).withAlpha(100),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.security_rounded,
            size: 44,
            color: Color(0xFF7B61FF),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Bienvenido',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Accede a tu cuenta de forma segura',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF777777),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      enableSuggestions: false,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: const InputDecoration(
        labelText: 'Correo electrónico',
        prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF555555), size: 20),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Ingresa tu correo';
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
        if (!emailRegex.hasMatch(v.trim())) return 'Correo no válido';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      enableSuggestions: false,
      autocorrect: false,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: const Icon(
          Icons.lock_outline_rounded,
          color: Color(0xFF555555),
          size: 20,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFF555555),
            size: 20,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
        if (v.length < 6) return 'Mínimo 6 caracteres';
        return null;
      },
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text('Iniciar sesión'),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(height: 1, color: const Color(0xFF2A2A2A)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            '¿No tienes cuenta?',
            style: TextStyle(color: Color(0xFF555555), fontSize: 13),
          ),
        ),
        Expanded(
          child: Container(height: 1, color: const Color(0xFF2A2A2A)),
        ),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: () => Navigator.pushNamed(context, '/register'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF7B61FF),
          side: const BorderSide(color: Color(0xFF7B61FF), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Crear cuenta nueva',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.no_photography_outlined, color: Color(0xFF555555), size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Las capturas de pantalla están desactivadas por políticas de seguridad.',
              style: TextStyle(color: Color(0xFF555555), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}