import 'package:dartz/dartz.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/jwt_decoder_util.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/jwt_token_manager.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../../core/utils/user_profile_validator.dart';
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
  Future<Either<Failure, AuthTokens>> loginWithUserName(
    String userName,
    String password,
  ) async {
    try {
      final tokens = await remoteDataSource.loginWithUserName({
        'userName': userName,
        'password': password,
      });

      await localDataSource.saveToken(tokens.token);

      // Extract and store user data from JWT token
      final tokenManager = getIt<JwtTokenManager>();
      final userData = await tokenManager.storeAndExtractToken(tokens.token);

      if (userData != null) {
        // Log extracted user data (excluding sensitive fields)
        final userInfo = JwtDecoderUtil.extractUserInfo(tokens.token);
        if (userInfo != null) {
          print('User logged in: ${userInfo['userName'] ?? userInfo['sub']}');
          print(
            'Available claims: ${JwtDecoderUtil.getAvailableClaims(tokens.token)}',
          );
        }
      }

      // Update session after successful login
      final sessionManager = getIt<SessionManager>();
      await sessionManager.updateLastActivity();

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
      // First try to revoke token on server
      try {
        await remoteDataSource.logout();
      } catch (e) {
        // Continue with local logout even if server logout fails
        print('Server logout failed, continuing with local logout: $e');
      }

      // Clear local token storage
      await localDataSource.clearToken();

      // Clear JWT token manager data
      final tokenManager = getIt<JwtTokenManager>();
      await tokenManager.clearStoredToken();

      // Clear session data
      final sessionManager = getIt<SessionManager>();
      await sessionManager.clearSession();

      // Clear any other sensitive data
      await _clearAllSensitiveData();

      return const Right(null);
    } catch (e) {
      // Even if there's an error, try to clear local data
      try {
        await localDataSource.clearToken();
        final tokenManager = getIt<JwtTokenManager>();
        await tokenManager.clearStoredToken();
        final sessionManager = getIt<SessionManager>();
        await sessionManager.clearSession();
        await _clearAllSensitiveData();
      } catch (clearError) {
        print('Error during cleanup after logout failure: $clearError');
      }

      // Still return success since we've cleared local data
      return const Right(null);
    }
  }

  // Helper method to clear all sensitive data
  Future<void> _clearAllSensitiveData() async {
    try {
      // Clear any additional sensitive data here
      // This could include cached user data, preferences, etc.
    } catch (e) {
      print('Error clearing sensitive data: $e');
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      // Use UserProfileValidator to get validated user data
      final userProfileValidator = getIt<UserProfileValidator>();
      final validProfile = await userProfileValidator.getValidUserProfile();

      if (validProfile != null) {
        final userData = validProfile['userData'] as Map<String, dynamic>;

        // Create User entity from validated data
        final user = User(
          Id: userData['Id'],
          userName: userData['userName'],
          Nama: userData['Nama'], //     '',
          // createdAt: DateTime.now().subtract(
          //   const Duration(days: 30),
          // ), // Default
          // updatedAt: DateTime.now(),
        );

        return Right(user);
      }

      // If no valid profile, try to get from local database
      final token = await localDataSource.getAccessToken();
      if (token != null) {
        // Try to extract user ID from token
        final decodedToken = JwtDecoderUtil.decodeAndFilterToken(token);
        if (decodedToken != null) {
          final userId = decodedToken['sub'] ?? decodedToken['id'];
          if (userId != null) {
            final localUser = await localDataSource.getUserById(
              userId.toString(),
            );
            if (localUser != null) {
              return Right(localUser);
            }
          }
        }
      }

      return Left(AuthFailure('No valid user data found'));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to get user data'));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await remoteDataSource.changePassword({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
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
  Future<bool> isLoggedIn() async {
    try {
      // Use UserProfileValidator to check if valid profile exists
      final userProfileValidator = getIt<UserProfileValidator>();
      final validProfile = await userProfileValidator.getValidUserProfile();

      return validProfile != null;
    } catch (e) {
      return false;
    }
  }

  /// Gets user permissions from JWT token
  Future<List<String>> getUserPermissions() async {
    try {
      final tokenManager = getIt<JwtTokenManager>();
      final claims = await tokenManager.getSpecificClaims([
        'permissions',
        'roles',
        'scope',
      ]);

      final List<String> permissions = [];

      // Extract permissions from various claim formats
      if (claims['permissions'] is List) {
        permissions.addAll((claims['permissions'] as List).cast<String>());
      }

      if (claims['roles'] is List) {
        permissions.addAll((claims['roles'] as List).cast<String>());
      }

      if (claims['scope'] is String) {
        permissions.addAll((claims['scope'] as String).split(' '));
      }

      return permissions.toSet().toList(); // Remove duplicates
    } catch (e) {
      return [];
    }
  }

  /// Gets custom user attributes from JWT token
  Future<Map<String, dynamic>> getUserAttributes() async {
    try {
      final tokenManager = getIt<JwtTokenManager>();
      return await tokenManager.getCustomClaims() ?? {};
    } catch (e) {
      return {};
    }
  }
}
