part of 'profile_bloc.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object> get props => [];
}

class ProfileLoadRequested extends ProfileEvent {
  const ProfileLoadRequested();
}

class PasswordChangeRequested extends ProfileEvent {
  final String userName;
  final String oldPassword;
  final String newPassword;
  final String confirmPassword;
  final String requestor;

  const PasswordChangeRequested({
    required this.userName,
    required this.oldPassword,
    required this.newPassword,
    required this.confirmPassword,
    required this.requestor,
  });

  @override
  List<Object> get props => [
    userName,
    oldPassword,
    newPassword,
    confirmPassword,
    requestor,
  ];
}