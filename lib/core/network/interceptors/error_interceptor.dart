import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../error/exceptions.dart';
import '../../utils/logger.dart';
import '../../widgets/network_error_widget.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppException exception;
    String userFriendlyMessage;

    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        exception = NetworkException('Connection timeout. Please check your internet connection.');
        userFriendlyMessage = 'Connection timed out. Please try again.';
        break;
        
      case DioExceptionType.badResponse:
        exception = _handleStatusCode(err.response?.statusCode, err.response?.data);
        userFriendlyMessage = exception.message;
        break;
        
      case DioExceptionType.cancel:
        exception = const AppException('Request was cancelled');
        userFriendlyMessage = 'Request was cancelled';
        break;
        
      case DioExceptionType.connectionError:
        exception = NetworkException('No internet connection. Please check your network settings.');
        userFriendlyMessage = 'No internet connection. Please check your network settings.';
        
        // Log additional connection error details for debugging
        AppLogger.error('Connection Error Details:');
        AppLogger.error('  URL: ${err.requestOptions.uri}');
        AppLogger.error('  Method: ${err.requestOptions.method}');
        AppLogger.error('  Error: ${err.error}');
        AppLogger.error('  Message: ${err.message}');
        
        // For Android emulator, provide specific guidance
        if (err.requestOptions.uri.host == 'localhost' || err.requestOptions.uri.host == '127.0.0.1') {
          userFriendlyMessage = 'Cannot connect to localhost. For Android emulator, use 10.0.2.2 instead.';
        }
        break;
        
      default:
        exception = const AppException('An unexpected error occurred');
        userFriendlyMessage = 'An unexpected network error occurred';
    }

    AppLogger.error('Network error: ${exception.message}');
    
    // Create enhanced DioException with user-friendly message
    final enhancedException = DioException(
      requestOptions: err.requestOptions,
      error: exception,
      type: err.type,
      response: err.response,
      message: userFriendlyMessage,
    );

    handler.reject(enhancedException);
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

/// Global error handler for network errors
class NetworkErrorHandler {
  static void showNetworkError(BuildContext context, {String? message, VoidCallback? onRetry}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NetworkErrorWidget(
          errorMessage: message,
          onRetry: () {
            Navigator.of(context).pop();
            onRetry?.call();
          },
        ),
      ),
    );
  }
}