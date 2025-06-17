part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

class AuthUsernameCheckResult extends AuthState {
  final String username;
  final bool isAvailable;

  const AuthUsernameCheckResult({
    required this.username,
    required this.isAvailable,
  });

  @override
  List<Object> get props => [username, isAvailable];
}

class AuthUsernameCheckError extends AuthState {
  final String message;

  const AuthUsernameCheckError(this.message);

  @override
  List<Object> get props => [message];
}