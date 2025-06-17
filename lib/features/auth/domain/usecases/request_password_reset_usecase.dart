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
      return Left(ValidationFailure(usernameError));
    }

    // Normalize username
    final normalizedUsername = UsernameValidator.normalize(username);

    // Request password reset
    return await repository.requestPasswordReset(normalizedUsername);
  }
}