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
  final String userName;
  final String password;

  const AuthLoginRequested({
    required this.userName,
    required this.password,
  });

  @override
  List<Object> get props => [userName, password];
}

class AuthLogoutRequested extends AuthEvent {
  final String? reason;

  const AuthLogoutRequested({this.reason});

  @override
  List<Object> get props => reason != null ? [reason!] : [];
}

class AuthTokenValidationRequested extends AuthEvent {
  const AuthTokenValidationRequested();
}

class AuthSessionStatusChanged extends AuthEvent {
  final SessionState sessionState;

  const AuthSessionStatusChanged(this.sessionState);

  @override
  List<Object> get props => [sessionState];
}