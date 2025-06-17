import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/username_validator.dart';
import '../repositories/auth_repository.dart';

class CheckUserNameAvailabilityUseCase {
  final AuthRepository repository;

  CheckUserNameAvailabilityUseCase(this.repository);

  Future<Either<Failure, bool>> call(String userName) async {
    // Validate userName format first
    final validationError = UserNameValidator.validateFormat(userName);
    if (validationError != null) {
      return Left(ValidationFailure(validationError));
    }

    // Normalize userName
    final normalizedUserName = UserNameValidator.normalize(userName);

    // Check availability
    return await repository.checkUserNameAvailability(normalizedUserName);
  }
}