import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../entities/auth_tokens.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthTokens>> loginWithUsername(String username, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, AuthTokens>> refreshToken();
  Future<Either<Failure, User>> getCurrentUser();
  Future<Either<Failure, void>> changePassword(String currentPassword, String newPassword);
  Future<Either<Failure, bool>> checkUsernameAvailability(String username);
  Future<bool> isLoggedIn();
}