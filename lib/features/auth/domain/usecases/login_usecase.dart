import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/username_validator.dart';
import '../entities/auth_tokens.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Either<Failure, AuthTokens>> call(String username, String password) async {
    // Validate username format
    final usernameError = UsernameValidator.validateFormat(username);
    if (usernameError != null) {
      return Left(ValidationFailure(usernameError));
    }

    // Validate password
    if (password.isEmpty) {
      return Left(ValidationFailure('Password is required'));
    }

    // Normalize username
    final normalizedUsername = UsernameValidator.normalize(username);

    // Attempt login
    return await repository.loginWithUsername(normalizedUsername, password);
  }
}