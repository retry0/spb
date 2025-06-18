import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/qr_code.dart';
import '../../domain/repositories/qr_code_repository.dart';
import '../datasources/qr_code_local_datasource.dart';
import '../datasources/qr_code_remote_datasource.dart';
import '../models/qr_code_model.dart';

class QrCodeRepositoryImpl implements QrCodeRepository {
  final QrCodeRemoteDataSource remoteDataSource;
  final QrCodeLocalDataSource localDataSource;
  final Uuid uuid;

  QrCodeRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.uuid,
  });

  @override
  Future<Either<Failure, QrCode>> generateQrCode({
    required String driver,
    required String kdVendor,
    int size = 300,
    String errorCorrectionLevel = 'M',
    String? foregroundColor,
    String? backgroundColor,
  }) async {
    try {
      // Call API to get QR code content
      final response = await remoteDataSource.getQrCodeForDriver(
        driver: driver,
        kdVendor: kdVendor,
      );

      if (!response.success || response.content == null) {
        return Left(ServerFailure(
          response.message ?? 'Failed to generate QR code',
        ));
      }

      // Create QR code model
      final qrCode = QrCodeModel(
        id: uuid.v4(),
        driver: driver,
        kdVendor: kdVendor,
        content: response.content!,
        size: size,
        errorCorrectionLevel: errorCorrectionLevel,
        foregroundColor: foregroundColor ?? '#000000',
        backgroundColor: backgroundColor ?? '#FFFFFF',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return Right(qrCode);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> saveQrCode(QrCode qrCode) async {
    try {
      final qrCodeModel = QrCodeModel.fromEntity(qrCode);
      final result = await localDataSource.saveQrCode(qrCodeModel);
      return Right(result);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to save QR code: $e'));
    }
  }

  @override
  Future<Either<Failure, List<QrCode>>> getSavedQrCodes() async {
    try {
      final qrCodes = await localDataSource.getSavedQrCodes();
      return Right(qrCodes);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get saved QR codes: $e'));
    }
  }

  @override
  Future<Either<Failure, QrCode>> getQrCodeById(String id) async {
    try {
      final qrCode = await localDataSource.getQrCodeById(id);
      return Right(qrCode);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get QR code: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteQrCode(String id) async {
    try {
      final result = await localDataSource.deleteQrCode(id);
      return Right(result);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to delete QR code: $e'));
    }
  }

  @override
  Future<Either<Failure, int>> getStorageUsage() async {
    try {
      final usage = await localDataSource.getStorageUsage();
      return Right(usage);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to get storage usage: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isStorageNearingCapacity() async {
    try {
      final isNearingCapacity = await localDataSource.isStorageNearingCapacity();
      return Right(isNearingCapacity);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to check storage capacity: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> exportQrCodeAsImage(
    QrCode qrCode,
    String format,
    int size,
  ) async {
    try {
      final qrCodeModel = QrCodeModel.fromEntity(qrCode);
      final filePath = await localDataSource.exportQrCodeAsImage(
        qrCodeModel,
        format,
        size,
      );
      return Right(filePath);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to export QR code: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> shareQrCode(
    QrCode qrCode,
    String format,
    int size,
  ) async {
    try {
      final qrCodeModel = QrCodeModel.fromEntity(qrCode);
      final result = await localDataSource.shareQrCode(
        qrCodeModel,
        format,
        size,
      );
      return Right(result);
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    } on PermissionException catch (e) {
      return Left(PermissionFailure(e.message));
    } catch (e) {
      return Left(CacheFailure('Failed to share QR code: $e'));
    }
  }
}