import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../entities/auth_tokens.dart';

abstract class AuthRepository {
  Future<Either<Failure, AuthTokens>> login(String email, String password);
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, AuthTokens>> refreshToken();
  Future<Either<Failure, User>> getCurrentUser();
  Future<bool> isLoggedIn();
}