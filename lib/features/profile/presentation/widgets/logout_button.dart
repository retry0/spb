import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Logout',
      onPressed: () => _showLogoutConfirmationDialog(context),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true, // User can dismiss by clicking outside
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthUnauthenticated) {
                  // Close dialog first
                  Navigator.of(dialogContext).pop();
                  
                  // Then navigate to login
                  context.go('/login');
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You have been successfully logged out'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (state is AuthError) {
                  // Show error message but still close dialog and redirect
                  Navigator.of(dialogContext).pop();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout error: ${state.message}'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  
                  // Still redirect to login since we want to force logout
                  context.go('/login');
                }
              },
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                
                return ElevatedButton(
                  onPressed: isLoading ? null : () => _performLogout(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Logout'),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _performLogout(BuildContext context) {
    // Dispatch logout event
    context.read<AuthBloc>().add(const AuthLogoutRequested(reason: 'User initiated logout'));
  }
}