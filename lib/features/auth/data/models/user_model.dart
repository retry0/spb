import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.email,
    required super.name,
    super.avatar,
    super.lastLogin,
    super.failedLoginAttempts = 0,
    super.lockedUntil,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  factory UserModel.fromDatabase(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] as String,
      username: data['username'] as String,
      email: data['email'] as String,
      name: data['name'] as String,
      avatar: data['avatar'] as String?,
      lastLogin: data['last_login'] != null 
          ? DateTime.fromMillisecondsSinceEpoch((data['last_login'] as int) * 1000)
          : null,
      failedLoginAttempts: data['failed_login_attempts'] as int? ?? 0,
      lockedUntil: data['locked_until'] != null
          ? DateTime.fromMillisecondsSinceEpoch((data['locked_until'] as int) * 1000)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch((data['created_at'] as int) * 1000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch((data['updated_at'] as int) * 1000),
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'name': name,
      'avatar': avatar,
      'last_login': lastLogin?.millisecondsSinceEpoch ~/ 1000,
      'failed_login_attempts': failedLoginAttempts,
      'locked_until': lockedUntil?.millisecondsSinceEpoch ~/ 1000,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
      'updated_at': updatedAt.millisecondsSinceEpoch ~/ 1000,
    };
  }
}