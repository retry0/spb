import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

import '../../di/injection.dart';
import '../../storage/secure_storage.dart';
import '../../constants/storage_keys.dart';
import '../../utils/logger.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorage _secureStorage = getIt<SecureStorage>();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      final token = await _secureStorage.read(StorageKeys.accessToken);
      
      if (token != null && !JwtDecoder.isExpired(token)) {
        options.headers['Authorization'] = 'Bearer $token';
      } else if (token != null) {
        // Token is expired, try to refresh
        await _refreshToken();
        final newToken = await _secureStorage.read(StorageKeys.accessToken);
        if (newToken != null) {
          options.headers['Authorization'] = 'Bearer $newToken';
        }
      }
    } catch (e) {
      AppLogger.error('Auth interceptor error: $e');
    }
    
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        await _refreshToken();
        final newToken = await _secureStorage.read(StorageKeys.accessToken);
        
        if (newToken != null) {
          // Retry the original request with new token
          final requestOptions = err.requestOptions;
          requestOptions.headers['Authorization'] = 'Bearer $newToken';
          
          final dio = Dio();
          final response = await dio.fetch(requestOptions);
          handler.resolve(response);
          return;
        }
      } catch (e) {
        AppLogger.error('Token refresh failed: $e');
        // Clear tokens and redirect to login
        await _secureStorage.delete(StorageKeys.accessToken);
        await _secureStorage.delete(StorageKeys.refreshToken);
      }
    }
    
    handler.next(err);
  }

  Future<void> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(StorageKeys.refreshToken);
      
      if (refreshToken == null || JwtDecoder.isExpired(refreshToken)) {
        throw Exception('Refresh token is invalid or expired');
      }

      final dio = Dio();
      final response = await dio.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _secureStorage.write(StorageKeys.accessToken, data['access_token']);
        await _secureStorage.write(StorageKeys.refreshToken, data['refresh_token']);
      }
    } catch (e) {
      AppLogger.error('Token refresh error: $e');
      rethrow;
    }
  }
}