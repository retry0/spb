import 'package:equatable/equatable.dart';

class AuthTokens extends Equatable {
  final String accessToken;

  const AuthTokens({
    required this.accessToken,
  });

  @override
  List<Object> get props => [accessToken];
}