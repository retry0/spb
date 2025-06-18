import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/qr_code.dart';
import '../repositories/qr_code_repository.dart';

class GetSavedQrCodesUseCase {
  final QrCodeRepository repository;

  GetSavedQrCodesUseCase(this.repository);

  Future<Either<Failure, List<QrCode>>> call() async {
    return await repository.getSavedQrCodes();
  }
}