import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/change_password_usecase.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _profileRepository;
  final ChangePasswordUseCase _changePasswordUseCase;

  ProfileBloc({
    required ProfileRepository profileRepository,
    required ChangePasswordUseCase changePasswordUseCase,
  })  : _profileRepository = profileRepository,
        _changePasswordUseCase = changePasswordUseCase,
        super(const ProfileInitial()) {
    on<ProfileLoadRequested>(_onProfileLoadRequested);
    on<PasswordChangeRequested>(_onPasswordChangeRequested);
  }

  Future<void> _onProfileLoadRequested(
    ProfileLoadRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    final result = await _profileRepository.getUserProfile();

    await result.fold(
      (failure) async {
        emit(ProfileError(failure.message));
      },
      (user) async {
        emit(ProfileLoaded(user: user));
      },
    );
  }

  Future<void> _onPasswordChangeRequested(
    PasswordChangeRequested event,
    Emitter<ProfileState> emit,
  ) async {
    // Keep current profile state while changing password
    final currentState = state;
    emit(const PasswordChangeLoading());

    // Validate password confirmation
    if (event.newPassword != event.confirmPassword) {
      emit(const PasswordChangeError('New passwords do not match'));
      // Restore previous state
      emit(currentState);
      return;
    }

    final result = await _changePasswordUseCase(
      userName: event.userName,
      oldPassword: event.oldPassword,
      newPassword: event.newPassword,
      requestor: event.requestor,
    );

    await result.fold(
      (failure) async {
        emit(PasswordChangeError(failure.message));
        // Restore previous state
        emit(currentState);
      },
      (_) async {
        emit(const PasswordChangeSuccess('Password changed successfully'));
        // Restore previous state
        emit(currentState);
      },
    );
  }
}