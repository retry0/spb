import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final AuthRepository authRepository;
  final ProfileRemoteDataSource remoteDataSource;

  ProfileRepositoryImpl({
    required this.authRepository,
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, User>> getUserProfile() async {
    // Get user from auth repository (from JWT token)
    return await authRepository.getCurrentUser();
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
}