import 'dart:async';
import 'package:flutter/material.dart';
import '../services/session_service.dart';

const Duration kInactivityTimeout = Duration(seconds: 15);

class InactivityDetector extends StatefulWidget {
  const InactivityDetector({super.key, required this.child});

  final Widget child;

  static InactivityDetectorState? of(BuildContext context) {
    return context.findAncestorStateOfType<InactivityDetectorState>();
  }

  @override
  State<InactivityDetector> createState() => InactivityDetectorState();
}

class InactivityDetectorState extends State<InactivityDetector> {
  Timer? _timer;
  ValueNotifier<int> secondsRemaining = ValueNotifier(kInactivityTimeout.inSeconds);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    secondsRemaining.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    secondsRemaining.value = kInactivityTimeout.inSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      final newValue = secondsRemaining.value - 1;
      secondsRemaining.value = newValue;

      if (newValue <= 0) {
        t.cancel();
        _onInactivityTimeout();
      }
    });
  }

  void resetTimer() {
    if (SessionService.instance.isLoggedIn) {
      _startTimer();
    }
  }

  void pauseTimer() {
    _timer?.cancel();
    secondsRemaining.value = kInactivityTimeout.inSeconds;
  }

  void _onInactivityTimeout() {
    if (SessionService.instance.isLoggedIn) {
      SessionService.instance.logout(
        reason: SessionCloseReason.inactivity,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => resetTimer(),
      onPointerMove: (_) => resetTimer(),
      child: widget.child,
    );
  }
}
