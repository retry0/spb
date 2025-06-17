import 'package:flutter/material.dart';
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
    on(_onAuthCheckRequested);
    on(_onAuthLoginRequested);
    on(_onAuthLogoutRequested);
    on(_onAuthTokenRefreshRequested);
    on(_onAuthUsernameAvailabilityRequested);
    on(_onAuthPasswordResetRequested);
    on(_onAuthPasswordResetConfirmRequested);
  }

  Future _onAuthCheckRequested(AuthCheckRequested event, Emitter emit) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(seconds: 1)); // Simulate check

    emit(const AuthUnauthenticated());
  }

  Future _onAuthLoginRequested(AuthLoginRequested event, Emitter emit) async {
    emit(const AuthLoading());
    final result = await loginUseCase(event.username, event.password);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (tokens) => emit(
        AuthAuthenticated(
          user: User(
            id: '1',
            username: event.username,
            email: '${event.username}@example.com',
            name: event.username
                .replaceAll('_', ' ')
                .split(' ')
                .map(
                  (word) =>
                      word.isNotEmpty
                          ? word[0].toUpperCase() + word.substring(1)
                          : word,
                )
                .join(' '),
            createdAt: DateTime.now().subtract(const Duration(days: 30)),
            updatedAt: DateTime.now(),
          ),
        ),
      ),
    );
  }

  Future _onAuthLogoutRequested(AuthLogoutRequested event, Emitter emit) async {
    emit(const AuthLoading());
    final result = await logoutUseCase();

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }

  Future _onAuthTokenRefreshRequested(
    AuthTokenRefreshRequested event,
    Emitter emit,
  ) async {
    final result = await refreshTokenUseCase();
    result.fold((failure) => emit(const AuthUnauthenticated()), (tokens) {
      // Keep current state but with refreshed tokens
      if (state is AuthAuthenticated) {
        emit(state);
      }
    });
  }

  Future _onAuthUsernameAvailabilityRequested(
    AuthUsernameAvailabilityRequested event,
    Emitter emit,
  ) async {
    final result = await checkUsernameAvailabilityUseCase(event.username);
    result.fold(
      (failure) => emit(AuthUsernameCheckError(failure.message)),
      (isAvailable) => emit(
        AuthUsernameCheckResult(
          username: event.username,
          isAvailable: isAvailable,
        ),
      ),
    );
  }

  Future _onAuthPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter emit,
  ) async {
    emit(const AuthPasswordResetLoading());
    final result = await requestPasswordResetUseCase(event.username);

    result.fold(
      (failure) => emit(AuthPasswordResetError(failure.message)),
      (_) => emit(const AuthPasswordResetEmailSent()),
    );
  }

  Future _onAuthPasswordResetConfirmRequested(
    AuthPasswordResetConfirmRequested event,
    Emitter emit,
  ) async {
    emit(const AuthPasswordResetLoading());
    final result = await resetPasswordUseCase(event.token, event.newPassword);

    result.fold(
      (failure) => emit(AuthPasswordResetError(failure.message)),
      (_) => emit(const AuthPasswordResetSuccess()),
    );
  }
}
