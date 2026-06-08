import 'dart:async';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class SessionTimeoutWrapper extends StatefulWidget {
  final Widget child;
  final Duration timeout;
  final VoidCallback onLogout;

  const SessionTimeoutWrapper({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: 5), // Tiempo configurable
    required this.onLogout
  });

  @override
  State<SessionTimeoutWrapper> createState() => _SessionTimeoutWrapperState();
}

class _SessionTimeoutWrapperState extends State<SessionTimeoutWrapper> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(widget.timeout, _handleInactivity);
  }

  void _handleInactivity() async {
    // Almacenar token y tiempo antes de cerrar
    await StorageService.saveSessionData(
        "TOKEN_SESION_ACTUAL", // Aquí iría tu token real
        DateTime.now().toIso8601String()
    );

    widget.onLogout();
  }

  // Detecta cualquier interacción del usuario
  void _onUserInteraction([_]) {
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onUserInteraction,
      onPointerMove: _onUserInteraction,
      child: widget.child,
    );
  }
}