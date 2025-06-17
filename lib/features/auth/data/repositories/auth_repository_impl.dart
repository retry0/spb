import 'package:dartz/dartz.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/security/password_security.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/auth_tokens.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_local_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  static const int maxFailedAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 30);

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, AuthTokens>> loginWithUsername(String username, String password) async {
    try {
      // Check if user exists locally first
      final localUser = await localDataSource.getUser(username);
      
      if (localUser != null) {
        // Check if user is locked
        if (localUser.isLocked) {
          await localDataSource.logAuthAttempt(username, 'login', false, errorMessage: 'Account is locked');
          return const Left(AuthFailure('Account is temporarily locked due to too many failed attempts. Please try again later.'));
        }

        // Verify password locally
        final isValidPassword = await localDataSource.verifyPassword(username, password);
        
        if (!isValidPassword) {
          await localDataSource.incrementFailedAttempts(username);
          
          // Check if we should lock the account
          final updatedUser = await localDataSource.getUser(username);
          if (updatedUser != null && updatedUser.failedLoginAttempts >= maxFailedAttempts) {
            final lockUntil = DateTime.now().add(lockoutDuration);
            await localDataSource.lockUser(username, lockUntil);
            await localDataSource.logAuthAttempt(username, 'login', false, errorMessage: 'Account locked due to too many failed attempts');
            return const Left(AuthFailure('Too many failed attempts. Account has been locked for 30 minutes.'));
          }
          
          await localDataSource.logAuthAttempt(username, 'login', false, errorMessage: 'Invalid password');
          return const Left(AuthFailure('Invalid username or password'));
        }

        // Reset failed attempts on successful login
        await localDataSource.resetFailedAttempts(username);
        
        // Update last login
        final updatedUser = localUser.copyWith(
          lastLogin: DateTime.now(),
          failedLoginAttempts: 0,
          lockedUntil: null,
        );
        await localDataSource.updateUser(UserModel(
          id: updatedUser.id,
          username: updatedUser.username,
          email: updatedUser.email,
          name: updatedUser.name,
          avatar: updatedUser.avatar,
          lastLogin: updatedUser.lastLogin,
          failedLoginAttempts: updatedUser.failedLoginAttempts,
          lockedUntil: updatedUser.lockedUntil,
          createdAt: updatedUser.createdAt,
          updatedAt: DateTime.now(),
        ));
      }

      // Attempt remote login
      final tokens = await remoteDataSource.loginWithUsername({
        'username': username,
        'password': password,
      });
      
      await localDataSource.saveTokens(tokens.accessToken, tokens.refreshToken);
      
      return Right(tokens);
    } on AuthException catch (e) {
      await localDataSource.logAuthAttempt(username, 'login', false, errorMessage: e.message);
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      await localDataSource.logAuthAttempt(username, 'login', false, errorMessage: e.message);
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      await localDataSource.logAuthAttempt(username, 'login', false, errorMessage: e.message);
      return Left(ServerFailure(e.message));
    } catch (e) {
      await localDataSource.logAuthAttempt(username, 'login', false, errorMessage: e.toString());
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
  Future<Either<Failure, void>> requestPasswordReset(String username) async {
    try {
      // Generate reset token
      const uuid = Uuid();
      final token = uuid.v4();
      final expiresAt = DateTime.now().add(const Duration(hours: 1));
      
      // Save token locally
      await localDataSource.savePasswordResetToken(username, token, expiresAt);
      
      // Send reset request to server
      await remoteDataSource.requestPasswordReset({
        'username': username,
        'token': token,
      });
      
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to request password reset'));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String token, String newPassword) async {
    try {
      // Verify token locally
      final tokenData = await localDataSource.getPasswordResetToken(token);
      if (tokenData == null) {
        return const Left(AuthFailure('Invalid or expired reset token'));
      }
      
      final username = tokenData['username'] as String;
      
      // Update password locally
      await localDataSource.updatePassword(username, newPassword);
      
      // Mark token as used
      await localDataSource.markPasswordResetTokenUsed(token);
      
      // Send to server
      await remoteDataSource.resetPassword({
        'token': token,
        'new_password': newPassword,
      });
      
      // Log the password reset
      await localDataSource.logAuthAttempt(username, 'password_reset', true);
      
      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to reset password'));
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

  @override
  Future<void> logAuthAttempt(String username, String action, bool success, {String? errorMessage}) async {
    await localDataSource.logAuthAttempt(username, action, success, errorMessage: errorMessage);
  }
}