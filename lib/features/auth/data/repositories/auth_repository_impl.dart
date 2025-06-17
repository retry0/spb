import 'package:dartz/dartz.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, AuthTokens>> loginWithUsername(String username, String password) async {
    try {
      final tokens = await remoteDataSource.loginWithUsername({
        'username': username,
        'password': password,
      });
      
      await localDataSource.saveTokens(tokens.accessToken, tokens.refreshToken);
      
      return Right(tokens);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred during login'));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await remoteDataSource.logout();
      await localDataSource.clearTokens();
      return const Right(null);
    } catch (e) {
      // Even if remote logout fails, clear local tokens
      await localDataSource.clearTokens();
      return const Right(null);
    }
  }

  @override
  Future<Either<Failure, AuthTokens>> refreshToken() async {
    try {
      final refreshToken = await localDataSource.getRefreshToken();
      
      if (refreshToken == null) {
        return const Left(AuthFailure('No refresh token available'));
      }

      final tokens = await remoteDataSource.refreshToken({
        'refresh_token': refreshToken,
      });
      
      await localDataSource.saveTokens(tokens.accessToken, tokens.refreshToken);
      
      return Right(tokens);
    } on AuthException catch (e) {
      await localDataSource.clearTokens();
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to refresh token'));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get user data'));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword(String currentPassword, String newPassword) async {
    try {
      await remoteDataSource.changePassword({
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to change password'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkUsernameAvailability(String username) async {
    try {
      // Check locally first
      final isLocallyAvailable = await localDataSource.isUsernameAvailable(username);
      if (!isLocallyAvailable) {
        return const Right(false);
      }
      
      // Check remotely
      final response = await remoteDataSource.checkUsernameAvailability(username);
      final isAvailable = response['available'] as bool? ?? false;
      
      return Right(isAvailable);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to check username availability'));
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final accessToken = await localDataSource.getAccessToken();
      
      if (accessToken == null) return false;
      
      return !JwtDecoder.isExpired(accessToken);
    } catch (e) {
      return false;
    }
  }
}