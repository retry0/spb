import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String userName;
  final String Nama;

  const User({required this.id, required this.userName, required this.Nama});

  User copyWith({String? id, String? userName, String? Nama}) {
    return User(
      id: id ?? this.id,
      userName: userName ?? this.userName,
      Nama: Nama ?? this.Nama,
    );
  }

  @override
  List<Object?> get props => [id, userName, Nama];
}
