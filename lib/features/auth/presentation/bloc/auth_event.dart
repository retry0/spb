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
  const AuthLogoutRequested();
}

class AuthTokenRefreshRequested extends AuthEvent {
  const AuthTokenRefreshRequested();
}

class AuthUserNameAvailabilityRequested extends AuthEvent {
  final String userName;

  const AuthUserNameAvailabilityRequested(this.userName);

  @override
  List<Object> get props => [userName];
}