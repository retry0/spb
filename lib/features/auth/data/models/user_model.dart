import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.userName,
    required super.Nama,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  factory UserModel.fromDatabase(Map<String, dynamic> data) {
    return UserModel(
      id: data['Id'] as String,
      userName: data['username'] as String,
      Nama: data['Nama'] as String,
    );
  }

  Map<String, dynamic> toDatabase() {
    return {'id': id, 'username': userName, 'Nama': Nama};
  }
}
