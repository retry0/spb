part of 'profile_bloc.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final User user;

  const ProfileLoaded({required this.user});

  @override
  List<Object> get props => [user];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object> get props => [message];
}

class PasswordChangeLoading extends ProfileState {
  const PasswordChangeLoading();
}

class PasswordChangeSuccess extends ProfileState {
  final String message;

  const PasswordChangeSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class PasswordChangeError extends ProfileState {
  final String message;

  const PasswordChangeError(this.message);

  @override
  List<Object> get props => [message];
}