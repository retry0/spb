import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/username_validator.dart';
import '../repositories/auth_repository.dart';

class RequestPasswordResetUseCase {
  final AuthRepository repository;

  RequestPasswordResetUseCase(this.repository);

  Future<Either<Failure, void>> call(String username) async {
    // Validate username format
    final usernameError = UsernameValidator.validateFormat(username);
    if (usernameError != null) {
      await repository.logAuthAttempt(username, 'password_reset_request', false, errorMessage: usernameError);
      return Left(ValidationFailure(usernameError));
    }

    // Normalize username
    final normalizedUsername = UsernameValidator.normalize(username);

    // Request password reset
    final result = await repository.requestPasswordReset(normalizedUsername);
    
    // Log the attempt
    result.fold(
      (failure) => repository.logAuthAttempt(normalizedUsername, 'password_reset_request', false, errorMessage: failure.message),
      (_) => repository.logAuthAttempt(normalizedUsername, 'password_reset_request', true),
    );

    return result;
  }
}