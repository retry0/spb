import 'package:equatable/equatable.dart';

class AuthTokens extends Equatable {
  final String token;

  const AuthTokens({required this.token});

  @override
  List<Object> get props => [token];
}
