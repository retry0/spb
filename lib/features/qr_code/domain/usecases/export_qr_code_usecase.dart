import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/qr_code.dart';
import '../repositories/qr_code_repository.dart';

class ExportQrCodeUseCase {
  final QrCodeRepository repository;

  ExportQrCodeUseCase(this.repository);

  Future<Either<Failure, String>> call({
    required QrCode qrCode,
    required String format,
    required int size,
  }) async {
    // Validate format
    final validFormats = ['png', 'jpg', 'svg'];
    if (!validFormats.contains(format.toLowerCase())) {
      return Left(ValidationFailure('Invalid format. Supported formats: PNG, JPG, SVG'));
    }

    // Validate size
    if (size < 128 || size > 2048) {
      return Left(ValidationFailure('Export size must be between 128 and 2048 pixels'));
    }

    return await repository.exportQrCodeAsImage(qrCode, format, size);
  }
}