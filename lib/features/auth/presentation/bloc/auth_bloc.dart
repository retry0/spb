import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import '../../domain/usecases/check_username_availability_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final RefreshTokenUseCase refreshTokenUseCase;
  final CheckUserNameAvailabilityUseCase checkUserNameAvailabilityUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.refreshTokenUseCase,
    required this.checkUserNameAvailabilityUseCase,
  }) : super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthTokenRefreshRequested>(_onAuthTokenRefreshRequested);
    on<AuthUserNameAvailabilityRequested>(_onAuthUserNameAvailabilityRequested);
  }

  Future _onAuthCheckRequested(AuthCheckRequested event, Emitter emit) async {
    emit(const AuthLoading());
    await Future.delayed(const Duration(seconds: 1)); // Simulate check

    emit(const AuthUnauthenticated());
  }

  Future _onAuthLoginRequested(AuthLoginRequested event, Emitter emit) async {
    emit(const AuthLoading());
    final result = await loginUseCase(event.userName, event.password);

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (tokens) => emit(
        AuthAuthenticated(
          user: User(
            id: '1',
            userName: event.userName,
            email: '${event.userName}@example.com',
            name: event.userName
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

  Future _onAuthUserNameAvailabilityRequested(
    AuthUserNameAvailabilityRequested event,
    Emitter emit,
  ) async {
    final result = await checkUserNameAvailabilityUseCase(event.userName);
    result.fold(
      (failure) => emit(AuthUserNameCheckError(failure.message)),
      (isAvailable) => emit(
        AuthUserNameCheckResult(
          userName: event.userName,
          isAvailable: isAvailable,
        ),
      ),
    );
  }
}