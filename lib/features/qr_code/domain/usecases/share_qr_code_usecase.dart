import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/qr_code.dart';
import '../repositories/qr_code_repository.dart';

class ShareQrCodeUseCase {
  final QrCodeRepository repository;

  ShareQrCodeUseCase(this.repository);

  Future<Either<Failure, bool>> call({
    required QrCode qrCode,
    String format = 'png',
    int size = 800,
  }) async {
    // Validate format
    final validFormats = ['png', 'jpg', 'svg'];
    if (!validFormats.contains(format.toLowerCase())) {
      return Left(ValidationFailure('Invalid format. Supported formats: PNG, JPG, SVG'));
    }

    // Validate size
    if (size < 128 || size > 2048) {
      return Left(ValidationFailure('Share size must be between 128 and 2048 pixels'));
    }

    return await repository.shareQrCode(qrCode, format, size);
  }
}