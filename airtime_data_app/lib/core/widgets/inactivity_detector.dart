import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/authentication/bloc/auth_bloc.dart';
import '../../features/authentication/event/auth_event.dart';
import '../../features/authentication/state/auth_state.dart';

/// Wraps the app and automatically logs the user out after [timeout] of
/// inactivity (no pointer/touch events). The timer only runs while the user
/// is authenticated; it is started on login and cancelled on logout.
class InactivityDetector extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;
  final Duration timeout;

  const InactivityDetector({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.timeout = const Duration(seconds: 90),
  });

  @override
  State<InactivityDetector> createState() => _InactivityDetectorState();
}

class _InactivityDetectorState extends State<InactivityDetector> {
  Timer? _timer;

  // States that mean the user is inside the authenticated area of the app.
  bool _isAuthenticated(AuthState state) =>
      state is LoginSuccess ||
      state is AuthSuccess ||
      state is ProfileSuccess ||
      state is ProfileLoading ||
      state is ProfileFailure ||
      state is WalletSuccess ||
      state is WalletLoading ||
      state is WalletFailure ||
      state is PasswordChangedSuccess ||
      state is PasswordChangedFailure;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(widget.timeout, _onInactive);
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Reset only if the timer is already running (i.e. user is authenticated).
  void _resetTimer() {
    if (_timer != null) _startTimer();
  }

  void _onInactive() {
    if (!mounted) return;
    // Clear tokens and reset auth state.
    context.read<AuthBloc>().add(const LogoutEvent());
    // Navigate to welcome, removing all previous routes.
    widget.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/welcome',
      (route) => false,
      arguments: {'reason': 'inactivity'},
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (ctx, state) {
        if (_isAuthenticated(state)) {
          _startTimer();
        } else if (state is AuthInitial) {
          _cancelTimer();
        }
      },
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _resetTimer(),
        child: widget.child,
      ),
    );
  }
}
