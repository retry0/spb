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

class AuthUserNameCheckResult extends AuthState {
  final String userName;
  final bool isAvailable;

  const AuthUserNameCheckResult({
    required this.userName,
    required this.isAvailable,
  });

  @override
  List<Object> get props => [userName, isAvailable];
}

class AuthUserNameCheckError extends AuthState {
  final String message;

  const AuthUserNameCheckError(this.message);

  @override
  List<Object> get props => [message];
}
