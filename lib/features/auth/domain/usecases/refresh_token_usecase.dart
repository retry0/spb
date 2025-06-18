import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_tokens.dart';
import '../repositories/auth_repository.dart';

/// Use case for refreshing authentication tokens
/// Note: This implementation now focuses on token validation and re-authentication
class RefreshTokenUseCase {
  final AuthRepository repository;

  RefreshTokenUseCase(this.repository);

  /// Validates current token and handles re-authentication if needed
  /// Since we removed refresh tokens, this now checks token validity
  /// and prompts for re-authentication when the token expires
  Future<Either<Failure, bool>> call() async {
    try {
      // Check if user is currently logged in with valid token
      final isLoggedIn = await repository.isLoggedIn();
      
      if (isLoggedIn) {
        // Token is still valid
        return const Right(true);
      } else {
        // Token is expired or invalid, user needs to re-authenticate
        return const Left(AuthFailure('Authentication token has expired. Please log in again.'));
      }
    } catch (e) {
      return Left(AuthFailure('Failed to validate authentication token'));
    }
  }
}