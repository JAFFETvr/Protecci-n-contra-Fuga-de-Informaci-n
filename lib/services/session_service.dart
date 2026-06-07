import 'package:flutter/material.dart';
import 'secure_storage_service.dart';

enum SessionCloseReason { inactivity, manual, none }

class SessionService extends ChangeNotifier {
  SessionService._();
  static final SessionService instance = SessionService._();

  bool _isLoggedIn = false;
  String? _token;
  SessionCloseReason _lastCloseReason = SessionCloseReason.none;

  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;
  SessionCloseReason get lastCloseReason => _lastCloseReason;

  GlobalKey<NavigatorState>? navigatorKey;

  void startSession(String token) {
    _token = token;
    _isLoggedIn = true;
    _lastCloseReason = SessionCloseReason.none;
    notifyListeners();
  }

  Future<void> logout({
    SessionCloseReason reason = SessionCloseReason.manual,
  }) async {
    if (!_isLoggedIn) return;

    final tokenToSave = _token ?? 'unknown';
    final closedAt = DateTime.now();

    await SecureStorageService.instance.saveSession(
      token: tokenToSave,
      closedAt: closedAt,
    );

    _isLoggedIn = false;
    _token = null;
    _lastCloseReason = reason;
    notifyListeners();

    navigatorKey?.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }
}
