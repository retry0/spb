import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/username_validator.dart';
import '../repositories/auth_repository.dart';

class CheckUsernameAvailabilityUseCase {
  final AuthRepository repository;

  CheckUsernameAvailabilityUseCase(this.repository);

  Future<Either<Failure, bool>> call(String username) async {
    // Validate username format first
    final validationError = UsernameValidator.validateFormat(username);
    if (validationError != null) {
      return Left(ValidationFailure(validationError));
    }

    // Normalize username
    final normalizedUsername = UsernameValidator.normalize(username);

    // Check availability
    return await repository.checkUsernameAvailability(normalizedUsername);
  }
}