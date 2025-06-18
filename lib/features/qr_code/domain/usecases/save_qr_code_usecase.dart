import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/qr_code.dart';
import '../repositories/qr_code_repository.dart';

class SaveQrCodeUseCase {
  final QrCodeRepository repository;

  SaveQrCodeUseCase(this.repository);

  Future<Either<Failure, bool>> call(QrCode qrCode) async {
    // Check if storage is nearing capacity before saving
    final storageResult = await repository.isStorageNearingCapacity();
    
    return await storageResult.fold(
      (failure) => Left(failure),
      (isNearingCapacity) async {
        if (isNearingCapacity) {
          return Left(StorageFailure(
            'Storage is nearing capacity. Please delete some QR codes before saving new ones.'
          ));
        }
        
        return await repository.saveQrCode(qrCode);
      },
    );
  }
}