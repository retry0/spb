import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/qr_code.dart';

abstract class QrCodeRepository {
  /// Generate a QR code for a driver
  Future<Either<Failure, QrCode>> generateQrCode({
    required String driver,
    required String kdVendor,
    int size = 300,
    String errorCorrectionLevel = 'M',
    String? foregroundColor,
    String? backgroundColor,
  });
  
  /// Save a generated QR code to local storage
  Future<Either<Failure, bool>> saveQrCode(QrCode qrCode);
  
  /// Get all saved QR codes
  Future<Either<Failure, List<QrCode>>> getSavedQrCodes();
  
  /// Get a specific QR code by ID
  Future<Either<Failure, QrCode>> getQrCodeById(String id);
  
  /// Delete a QR code from storage
  Future<Either<Failure, bool>> deleteQrCode(String id);
  
  /// Get the total storage usage for QR codes
  Future<Either<Failure, int>> getStorageUsage();
  
  /// Check if the storage is nearing capacity
  Future<Either<Failure, bool>> isStorageNearingCapacity();
  
  /// Export a QR code as an image file
  Future<Either<Failure, String>> exportQrCodeAsImage(
    QrCode qrCode, 
    String format,
    int size,
  );
  
  /// Share a QR code
  Future<Either<Failure, bool>> shareQrCode(
    QrCode qrCode,
    String format,
    int size,
  );
}