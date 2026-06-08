import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/session_service.dart';
import 'services/secure_storage_service.dart';
import 'widgets/inactivity_detector.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Notificación en background recibida: ${message.messageId}");
  
  if (message.data['action'] == 'WIPE_DATA') {
    print("⚠️ Comando de WIPE remoto recibido en BACKGROUND.");
    await SecureStorageService.instance.wipeData();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Firebase
  await Firebase.initializeApp();
  
  // Configurar background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  // Solicitar permisos de notificación
  await FirebaseMessaging.instance.requestPermission();
  
  // Obtener e imprimir el token FCM para pruebas
  String? token = await FirebaseMessaging.instance.getToken();
  print("========================================");
  print("🔥 FCM TOKEN DEL DISPOSITIVO:");
  print(token);
  print("========================================");
  
  // Inicializar datos sensibles en Secure Storage
  await SecureStorageService.instance.initializeSensitiveData();
  await SecureStorageService.instance.printCurrentData();
  
  // Configurar foreground handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print("📩 Notificación en foreground recibida: ${message.messageId}");
    if (message.data['action'] == 'WIPE_DATA') {
      print("⚠️ Comando de WIPE remoto recibido en FOREGROUND.");
      await SecureStorageService.instance.wipeData();
    }
  });

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0D0D0D),
    ),
  );

  bool fakeGpsDetected = await isFakeGpsDetected();

  runApp(MyApp(fakeGpsDetected: fakeGpsDetected));
}

Future<bool> isFakeGpsDetected() async {
  if (Platform.isIOS) return false;

  try {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      return position.isMocked;
    } catch (_) {
      return false;
    }
  } catch (e) {
    return false;
  }
}

class MyApp extends StatelessWidget {
  final bool fakeGpsDetected;

  const MyApp({super.key, this.fakeGpsDetected = false});

  @override
  Widget build(BuildContext context) {
    if (fakeGpsDetected) {
      return MaterialApp(
        title: 'DLP Seguro',
        debugShowCheckedModeBanner: false,
        theme: _buildDarkTheme(),
        home: const FakeGpsDetectedScreen(),
      );
    }

    final navigatorKey = GlobalKey<NavigatorState>();
    SessionService.instance.navigatorKey = navigatorKey;

    return InactivityDetector(
      child: MaterialApp(
        title: 'DLP Seguro',
        debugShowCheckedModeBanner: false,
        theme: _buildDarkTheme(),
        navigatorKey: navigatorKey,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/dashboard': (context) => const DashboardScreen(),
        },
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const primary = Color(0xFF7B61FF);
    const bg = Color(0xFF0D0D0D);
    const surface = Color(0xFF1A1A1A);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: Color(0xFF00D4FF),
        surface: surface,
        error: Color(0xFFFF4757),
      ),
      fontFamily: 'Roboto',
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFFF4757), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFFFF4757), width: 1.5),
        ),
        labelStyle: const TextStyle(color: Color(0xFF777777)),
        errorStyle: const TextStyle(color: Color(0xFFFF4757)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: primary.withAlpha(100),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF111111),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
    );
  }
}

class FakeGpsDetectedScreen extends StatelessWidget {
  const FakeGpsDetectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 80, color: Color(0xFFFF4757)),
            const SizedBox(height: 24),
            const Text(
              'Fake GPS Detectado',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF4757),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Esta aplicación no puede ejecutarse en un dispositivo con GPS simulado habilitado.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                exit(0);
              },
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Cerrar Aplicación'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4757),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
