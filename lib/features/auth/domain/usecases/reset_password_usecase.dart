import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(String token, String newPassword) async {
    // Validate token
    if (token.isEmpty) {
      return const Left(ValidationFailure('Reset token is required'));
    }

    // Validate password
    if (newPassword.isEmpty) {
      return const Left(ValidationFailure('Password is required'));
    }

    if (newPassword.length < 8) {
      return const Left(ValidationFailure('Password must be at least 8 characters long'));
    }

    // Reset password
    return await repository.resetPassword(token, newPassword);
  }
}