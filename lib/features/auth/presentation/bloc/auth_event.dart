part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthLoginRequested({
    required this.username,
    required this.password,
  });

  @override
  List<Object> get props => [username, password];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

class AuthTokenRefreshRequested extends AuthEvent {
  const AuthTokenRefreshRequested();
}

class AuthUsernameAvailabilityRequested extends AuthEvent {
  final String username;

  const AuthUsernameAvailabilityRequested(this.username);

  @override
  List<Object> get props => [username];
}

class AuthPasswordResetRequested extends AuthEvent {
  final String username;

  const AuthPasswordResetRequested(this.username);

  @override
  List<Object> get props => [username];
}

class AuthPasswordResetConfirmRequested extends AuthEvent {
  final String token;
  final String newPassword;

  const AuthPasswordResetConfirmRequested({
    required this.token,
    required this.newPassword,
  });

  @override
  List<Object> get props => [token, newPassword];
}