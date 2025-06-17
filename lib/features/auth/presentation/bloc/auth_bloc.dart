import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import '../../domain/usecases/check_username_availability_usecase.dart';
import '../../domain/usecases/request_password_reset_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final RefreshTokenUseCase refreshTokenUseCase;
  final CheckUsernameAvailabilityUseCase checkUsernameAvailabilityUseCase;
  final RequestPasswordResetUseCase requestPasswordResetUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.refreshTokenUseCase,
    required this.checkUsernameAvailabilityUseCase,
    required this.requestPasswordResetUseCase,
    required this.resetPasswordUseCase,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthTokenRefreshRequested>(_onAuthTokenRefreshRequested);
    on<AuthUsernameAvailabilityRequested>(_onAuthUsernameAvailabilityRequested);
    on<AuthPasswordResetRequested>(_onAuthPasswordResetRequested);
    on<AuthPasswordResetConfirmRequested>(_onAuthPasswordResetConfirmRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    // Check if user is already logged in
    // This would typically involve checking stored tokens
    await Future.delayed(const Duration(seconds: 1)); // Simulate check
    
    emit(const AuthUnauthenticated());
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    final result = await loginUseCase(event.username, event.password);
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (tokens) => emit(const AuthAuthenticated(
        user: User(
          id: '1',
          username: 'johndoe',
          email: 'john.doe@example.com',
          name: 'John Doe',
          createdAt: null,
          updatedAt: null,
        ),
      )),
    );
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    final result = await logoutUseCase();
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  Future<void> _onAuthTokenRefreshRequested(
    AuthTokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await refreshTokenUseCase();
    
    result.fold(
      (failure) => emit(const AuthUnauthenticated()),
      (tokens) {
        // Keep current state but with refreshed tokens
        if (state is AuthAuthenticated) {
          emit(state);
        }
      },
    );
  }

  Future<void> _onAuthUsernameAvailabilityRequested(
    AuthUsernameAvailabilityRequested event,
    Emitter<AuthState> emit,
  ) async {
    final result = await checkUsernameAvailabilityUseCase(event.username);
    
    result.fold(
      (failure) => emit(AuthUsernameCheckError(failure.message)),
      (isAvailable) => emit(AuthUsernameCheckResult(
        username: event.username,
        isAvailable: isAvailable,
      )),
    );
  }

  Future<void> _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthPasswordResetLoading());
    
    final result = await requestPasswordResetUseCase(event.username);
    
    result.fold(
      (failure) => emit(AuthPasswordResetError(failure.message)),
      (_) => emit(const AuthPasswordResetEmailSent()),
    );
  }

  Future<void> _onAuthPasswordResetConfirmRequested(
    AuthPasswordResetConfirmRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthPasswordResetLoading());
    
    final result = await resetPasswordUseCase(event.token, event.newPassword);
    
    result.fold(
      (failure) => emit(AuthPasswordResetError(failure.message)),
      (_) => emit(const AuthPasswordResetSuccess()),
    );
  }
}