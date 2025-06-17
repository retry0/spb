import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/security/password_security.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordUseCase {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(String token, String newPassword) async {
    // Validate token
    if (token.isEmpty) {
      return const Left(ValidationFailure('Reset token is required'));
    }

    // Validate password strength
    final passwordStrength = PasswordSecurity.validatePasswordStrength(newPassword);
    if (passwordStrength == PasswordStrength.weak) {
      return Left(ValidationFailure(passwordStrength.description));
    }

    // Reset password
    return await repository.resetPassword(token, newPassword);
  }
}