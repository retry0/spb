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
      await repository.logAuthAttempt(username, 'login', false, errorMessage: usernameError);
      return Left(ValidationFailure(usernameError));
    }

    // Validate password
    if (password.isEmpty) {
      await repository.logAuthAttempt(username, 'login', false, errorMessage: 'Password is required');
      return Left(ValidationFailure('Password is required'));
    }

    // Normalize username
    final normalizedUsername = UsernameValidator.normalize(username);

    // Attempt login
    final result = await repository.loginWithUsername(normalizedUsername, password);
    
    // Log the attempt
    result.fold(
      (failure) => repository.logAuthAttempt(normalizedUsername, 'login', false, errorMessage: failure.message),
      (_) => repository.logAuthAttempt(normalizedUsername, 'login', true),
    );

    return result;
  }
}