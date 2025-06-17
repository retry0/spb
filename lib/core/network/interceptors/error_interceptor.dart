import 'package:dio/dio.dart';

import '../../error/exceptions.dart';
import '../../utils/logger.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppException exception;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        exception = NetworkException('Connection timeout. Please check your internet connection.');
        break;
      case DioExceptionType.badResponse:
        exception = _handleStatusCode(err.response?.statusCode, err.response?.data);
        break;
      case DioExceptionType.cancel:
        exception = const AppException('Request was cancelled');
        break;
      case DioExceptionType.connectionError:
        exception = NetworkException('No internet connection. Please check your network settings.');
        break;
      default:
        exception = const AppException('An unexpected error occurred');
    }

    AppLogger.error('Network error: ${exception.message}');
    handler.reject(DioException(
      requestOptions: err.requestOptions,
      error: exception,
      type: err.type,
      response: err.response,
    ));
  }

  AppException _handleStatusCode(int? statusCode, dynamic data) {
    switch (statusCode) {
      case 400:
        return ValidationException(data?['message'] ?? 'Bad request');
      case 401:
        return AuthException('Authentication failed. Please login again.');
      case 403:
        return AuthException('Access denied. You don\'t have permission to perform this action.');
      case 404:
        return const AppException('Resource not found');
      case 422:
        return ValidationException(data?['message'] ?? 'Validation failed');
      case 500:
        return const ServerException('Internal server error. Please try again later.');
      case 502:
      case 503:
      case 504:
        return const ServerException('Server is temporarily unavailable. Please try again later.');
      default:
        return AppException('Server error (${statusCode ?? 'Unknown'})');
    }
  }
}