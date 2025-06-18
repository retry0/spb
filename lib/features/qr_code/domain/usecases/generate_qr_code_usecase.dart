import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/qr_code.dart';
import '../repositories/qr_code_repository.dart';

class GenerateQrCodeUseCase {
  final QrCodeRepository repository;

  GenerateQrCodeUseCase(this.repository);

  Future<Either<Failure, QrCode>> call({
    required String driver,
    required String kdVendor,
    int size = 300,
    String errorCorrectionLevel = 'M',
    String? foregroundColor,
    String? backgroundColor,
  }) async {
    // Validate inputs
    if (driver.isEmpty) {
      return Left(ValidationFailure('Driver information is required'));
    }

    if (kdVendor.isEmpty) {
      return Left(ValidationFailure('Vendor information is required'));
    }

    // Validate size
    if (size < 128 || size > 1024) {
      return Left(ValidationFailure('Size must be between 128 and 1024 pixels'));
    }

    // Validate error correction level
    final validErrorLevels = ['L', 'M', 'Q', 'H'];
    if (!validErrorLevels.contains(errorCorrectionLevel)) {
      return Left(ValidationFailure('Invalid error correction level. Must be one of: L, M, Q, H'));
    }

    // Call repository to generate QR code
    return await repository.generateQrCode(
      driver: driver,
      kdVendor: kdVendor,
      size: size,
      errorCorrectionLevel: errorCorrectionLevel,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
    );
  }
}