import 'package:dio/dio.dart';

import '../../../../core/error/exceptions.dart';
import '../models/qr_code_response_model.dart';

abstract class QrCodeRemoteDataSource {
  /// Calls the /v1/SPB/api/GetSPBForDriver endpoint
  ///
  /// Throws a [ServerException] for all error codes
  Future<QrCodeResponseModel> getQrCodeForDriver({
    required String driver,
    required String kdVendor,
  });
}

class QrCodeRemoteDataSourceImpl implements QrCodeRemoteDataSource {
  final Dio dio;

  QrCodeRemoteDataSourceImpl({required this.dio});

  @override
  Future<QrCodeResponseModel> getQrCodeForDriver({
    required String driver,
    required String kdVendor,
  }) async {
    try {
      final response = await dio.get(
        '/v1/SPB/api/GetSPBForDriver',
        queryParameters: {
          'driver': driver,
          'kdVendor': kdVendor,
        },
      );

      if (response.statusCode == 200) {
        return QrCodeResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          'Failed to get QR code. Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      throw ServerException(
        'Failed to get QR code: ${e.message}',
      );
    } catch (e) {
      throw ServerException(
        'Unexpected error while getting QR code: $e',
      );
    }
  }
}