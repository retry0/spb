import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/storage/user_profile_repository.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final AuthRepository authRepository;
  final ProfileRemoteDataSource remoteDataSource;
  final UserProfileRepository userProfileRepository;

  ProfileRepositoryImpl({
    required this.authRepository,
    required this.remoteDataSource,
    required this.userProfileRepository,
  });

  @override
  Future<Either<Failure, User>> getUserProfile() async {
    try {
      // Get user profile from user profile repository
      final result = await userProfileRepository.getUserProfile();
      
      return result.fold(
        (failure) async {
          // Fallback to auth repository if user profile repository fails
          return await authRepository.getCurrentUser();
        },
        (userData) async {
          // Convert to User entity
          final user = User(
            id: userData['id'] ?? userData['sub'] ?? '',
            userName: userData['username'] ?? 
                     userData['userName'] ?? 
                     userData['preferred_username'] ?? '',
            email: userData['email'] ?? '',
            name: userData['name'] ?? 
                 userData['given_name'] ?? 
                 userData['userName'] ?? 
                 userData['username'] ?? '',
            avatar: userData['avatar'] ?? userData['picture'],
            createdAt: userData['created_at'] != null 
                ? DateTime.fromMillisecondsSinceEpoch(
                    (userData['created_at'] as int) * 1000)
                : DateTime.now().subtract(const Duration(days: 30)),
            updatedAt: userData['updated_at'] != null
                ? DateTime.fromMillisecondsSinceEpoch(
                    (userData['updated_at'] as int) * 1000)
                : DateTime.now(),
          );
          
          return Right(user);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Failed to get user profile: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String userName,
    required String oldPassword,
    required String newPassword,
    required String requestor,
  }) async {
    try {
      await remoteDataSource.changePassword({
        'userName': userName,
        'oldPassword': oldPassword,
        'newPassword': newPassword,
        'requestor': requestor,
      });

      return const Right(null);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('An unexpected error occurred while changing password'));
    }
  }
  
  @override
  Future<Either<Failure, User>> updateUserProfile(User user) async {
    try {
      // Convert User entity to Map
      final userData = {
        'id': user.id,
        'userName': user.userName,
        'username': user.userName, // For backward compatibility
        'email': user.email,
        'name': user.name,
        'avatar': user.avatar,
        'created_at': user.createdAt.millisecondsSinceEpoch ~/ 1000,
        'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      };
      
      // Update user profile
      final result = await userProfileRepository.updateUserProfile(userData);
      
      return result.fold(
        (failure) => Left(failure),
        (updatedData) {
          // Convert back to User entity
          final updatedUser = User(
            id: updatedData['id'] ?? updatedData['sub'] ?? '',
            userName: updatedData['userName'] ?? 
                     updatedData['username'] ?? 
                     updatedData['preferred_username'] ?? '',
            email: updatedData['email'] ?? '',
            name: updatedData['name'] ?? 
                 updatedData['given_name'] ?? 
                 updatedData['userName'] ?? 
                 updatedData['username'] ?? '',
            avatar: updatedData['avatar'] ?? updatedData['picture'],
            createdAt: updatedData['created_at'] != null 
                ? DateTime.fromMillisecondsSinceEpoch(
                    (updatedData['created_at'] as int) * 1000)
                : DateTime.now().subtract(const Duration(days: 30)),
            updatedAt: updatedData['updated_at'] != null
                ? DateTime.fromMillisecondsSinceEpoch(
                    (updatedData['updated_at'] as int) * 1000)
                : DateTime.now(),
          );
          
          return Right(updatedUser);
        },
      );
    } catch (e) {
      return Left(ServerFailure('Failed to update user profile: $e'));
    }
  }
  
  @override
  Future<Either<Failure, bool>> syncUserProfile() async {
    try {
      // Get user ID from current user
      final userResult = await getUserProfile();
      
      return await userResult.fold(
        (failure) => Left(failure),
        (user) async {
          // Sync user profile
          final result = await userProfileRepository.syncUserProfile(user.id);
          
          return result.fold(
            (failure) => Left(failure),
            (syncedData) => const Right(true),
          );
        },
      );
    } catch (e) {
      return Left(ServerFailure('Failed to sync user profile: $e'));
    }
  }
}