import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/auth_tokens.dart';

part 'auth_tokens_model.g.dart';

@JsonSerializable()
class AuthTokensModel extends AuthTokens {
  const AuthTokensModel({required super.accessToken});

  Map<String, dynamic> toJson() => _$AuthTokensModelToJson(this);
}
