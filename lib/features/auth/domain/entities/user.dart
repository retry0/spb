import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String email;
  final String name;
  final String? avatar;
  final DateTime? lastLogin;
  final int failedLoginAttempts;
  final DateTime? lockedUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.name,
    this.avatar,
    this.lastLogin,
    this.failedLoginAttempts = 0,
    this.lockedUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLocked {
    if (lockedUntil == null) return false;
    return DateTime.now().isBefore(lockedUntil!);
  }

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? name,
    String? avatar,
    DateTime? lastLogin,
    int? failedLoginAttempts,
    DateTime? lockedUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      lastLogin: lastLogin ?? this.lastLogin,
      failedLoginAttempts: failedLoginAttempts ?? this.failedLoginAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id, username, email, name, avatar, lastLogin, 
    failedLoginAttempts, lockedUntil, createdAt, updatedAt
  ];
}