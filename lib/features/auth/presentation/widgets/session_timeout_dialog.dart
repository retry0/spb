import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';

class SessionTimeoutDialog extends StatelessWidget {
  final int remainingMinutes;
  final VoidCallback onContinue;
  final VoidCallback onLogout;

  const SessionTimeoutDialog({
    super.key,
    this.remainingMinutes = 5,
    required this.onContinue,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Session Expiring Soon'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.timer,
            size: 48,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          Text(
            'Your session will expire in $remainingMinutes ${remainingMinutes == 1 ? 'minute' : 'minutes'} due to inactivity.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Would you like to continue your session?',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onLogout,
          child: const Text('Logout'),
        ),
        ElevatedButton(
          onPressed: onContinue,
          child: const Text('Continue Session'),
        ),
      ],
    );
  }
}

class SessionTimeoutManager extends StatelessWidget {
  final Widget child;

  const SessionTimeoutManager({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSessionExpiring) {
          _showSessionExpiringDialog(context, state.minutesRemaining);
        } else if (state is AuthSessionTimeout) {
          _showSessionTimeoutDialog(context);
        }
      },
      child: child,
    );
  }

  void _showSessionExpiringDialog(BuildContext context, int minutesRemaining) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SessionTimeoutDialog(
        remainingMinutes: minutesRemaining,
        onContinue: () {
          // Continue session
          context.read<AuthBloc>().add(
            const AuthTokenValidationRequested(),
          );
          Navigator.of(context).pop();
        },
        onLogout: () {
          // Logout
          context.read<AuthBloc>().add(
            const AuthLogoutRequested(reason: 'User logged out from session expiry dialog'),
          );
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showSessionTimeoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Expired'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer_off,
              size: 48,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Your session has expired due to inactivity.',
            ),
            SizedBox(height: 8),
            Text(
              'Please log in again to continue.',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}