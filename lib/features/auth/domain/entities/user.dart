import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String Id;
  final String userName;
  final String Nama;

  const User({required this.Id, required this.userName, required this.Nama});

  User copyWith({String? Id, String? userName, String? Nama}) {
    return User(
      Id: Id ?? this.Id,
      userName: userName ?? this.userName,
      Nama: Nama ?? this.Nama,
    );
  }

  @override
  List<Object?> get props => [Id, userName, Nama];
}
