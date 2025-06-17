import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.userName,
    required super.email,
    required super.name,
    super.avatar,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  factory UserModel.fromDatabase(Map<String, dynamic> data) {
    return UserModel(
      id: data['id'] as String,
      userName: data['username'] as String,
      email: data['email'] as String,
      name: data['name'] as String,
      avatar: data['avatar'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch((data['created_at'] as int) * 1000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch((data['updated_at'] as int) * 1000),
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'username': userName,
      'email': email,
      'name': name,
      'avatar': avatar,
      'created_at': createdAt.millisecondsSinceEpoch ~/ 1000,
      'updated_at': updatedAt.millisecondsSinceEpoch ~/ 1000,
    };
  }
}