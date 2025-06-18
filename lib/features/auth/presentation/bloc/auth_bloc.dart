import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import '../../../../core/utils/session_manager.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final RefreshTokenUseCase refreshTokenUseCase;
  final SessionManager sessionManager;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.refreshTokenUseCase,
    required this.sessionManager,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthTokenValidationRequested>(_onAuthTokenValidationRequested);
    on<AuthSessionStatusChanged>(_onAuthSessionStatusChanged);
    
    // Listen to session state changes
    sessionManager.sessionState.addListener(_onSessionStateChanged);
    
    // Initialize session
    sessionManager.initializeSession();
  }

  void _onSessionStateChanged() {
    final sessionState = sessionManager.sessionState.value;
    
    switch (sessionState) {
      case SessionState.active:
        // Session is active, no action needed
        break;
      case SessionState.expiring:
        // Token is expiring soon, trigger token validation
        add(const AuthTokenValidationRequested());
        break;
      case SessionState.timeout:
        // Session timed out, log out user
        add(const AuthLogoutRequested(reason: 'Session timed out due to inactivity'));
        break;
      case SessionState.inactive:
        // No active session, ensure user is logged out
        if (state is AuthAuthenticated) {
          add(const AuthLogoutRequested(reason: 'Session became inactive'));
        }
        break;
      case SessionState.error:
        // Error with session, log out user
        add(const AuthLogoutRequested(reason: 'Session error occurred'));
        break;
      case SessionState.unknown:
        // Initial state, no action needed
        break;
    }
  }

  Future<void> _onAuthCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    
    try {
      // Check if session is active
      final isActive = await sessionManager.isSessionActive();
      
      if (isActive) {
        // Get user data from token
        final result = await refreshTokenUseCase();
        
        await result.fold(
          (failure) async {
            emit(const AuthUnauthenticated());
          },
          (isValid) async {
            if (isValid) {
              // Get current user
              final userResult = await loginUseCase.repository.getCurrentUser();
              
              await userResult.fold(
                (failure) async {
                  emit(const AuthUnauthenticated());
                },
                (user) async {
                  emit(AuthAuthenticated(user: user));
                },
              );
            } else {
              emit(const AuthUnauthenticated());
            }
          },
        );
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthError('Failed to check authentication status: $e'));
    }
  }

  Future<void> _onAuthLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    final result = await loginUseCase(event.userName, event.password);

    await result.fold(
      (failure) async {
        emit(AuthError(failure.message));
      },
      (tokens) async {
        // Update session after successful login
        await sessionManager.updateLastActivity();
        
        // Get user from token
        final userResult = await loginUseCase.repository.getCurrentUser();
        
        await userResult.fold(
          (failure) async {
            emit(AuthError(failure.message));
          },
          (user) async {
            emit(AuthAuthenticated(user: user));
          },
        );
      },
    );
  }

  Future<void> _onAuthLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    
    // Log the reason if provided
    if (event.reason != null) {
      print('Logout requested: ${event.reason}');
    }
    
    // Use the logout use case with retry mechanism
    final result = await logoutUseCase(maxRetries: 3);

    // Clear session data
    await sessionManager.clearSession();

    await result.fold(
      (failure) async {
        emit(AuthError(failure.message));
      },
      (_) async {
        emit(const AuthUnauthenticated());
      },
    );
  }

  Future<void> _onAuthTokenValidationRequested(
    AuthTokenValidationRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await refreshTokenUseCase();
    await result.fold(
      (failure) async {
        emit(const AuthUnauthenticated());
      }, 
      (isValid) async {
        if (!isValid) {
          emit(const AuthUnauthenticated());
        }
        // If valid, keep current state
      }
    );
  }

  Future<void> _onAuthSessionStatusChanged(
    AuthSessionStatusChanged event,
    Emitter<AuthState> emit,
  ) async {
    switch (event.sessionState) {
      case SessionState.active:
        // No state change needed if already authenticated
        if (state is! AuthAuthenticated) {
          add(const AuthCheckRequested());
        }
        break;
      case SessionState.expiring:
        // Notify user that session is expiring soon
        if (state is AuthAuthenticated) {
          emit(AuthSessionExpiring(user: (state as AuthAuthenticated).user));
        }
        break;
      case SessionState.timeout:
        // Session timed out, log out user
        emit(const AuthSessionTimeout());
        add(const AuthLogoutRequested(reason: 'Session timeout'));
        break;
      case SessionState.inactive:
      case SessionState.error:
        // Log out user
        emit(const AuthUnauthenticated());
        break;
      case SessionState.unknown:
        // No action needed
        break;
    }
  }

  @override
  Future<void> close() {
    // Clean up listeners
    sessionManager.sessionState.removeListener(_onSessionStateChanged);
    return super.close();
  }
}