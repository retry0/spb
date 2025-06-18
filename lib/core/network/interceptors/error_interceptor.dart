import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../error/exceptions.dart';
import '../../utils/logger.dart';
import '../../widgets/network_error_widget.dart';
import '../models/api_error_response.dart';

class ErrorInterceptor extends Interceptor {
  final _uuid = const Uuid();

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final requestId = _uuid.v4();
    AppException exception;
    String userFriendlyMessage;
    ApiErrorResponse? apiErrorResponse;

    // Try to parse API error response if available
    if (err.response?.data != null) {
      try {
        if (err.response!.data is Map<String, dynamic>) {
          apiErrorResponse = ApiErrorResponse.fromJson(err.response!.data);
          exception = _createExceptionFromApiError(apiErrorResponse);
          userFriendlyMessage = apiErrorResponse.message;
        } else {
          // Fallback for non-JSON error responses
          exception = _handleStatusCode(
            err.response?.statusCode,
            err.response?.data,
            requestId,
          );
          userFriendlyMessage = exception.message;
        }
      } catch (parseError) {
        AppLogger.warning('Failed to parse API error response: $parseError');
        exception = _handleStatusCode(
          err.response?.statusCode,
          err.response?.data,
          requestId,
        );
        userFriendlyMessage = exception.message;
      }
    } else {
      // Handle network-level errors
      switch (err.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          apiErrorResponse = _createTimeoutErrorResponse(requestId);
          exception = NetworkException(apiErrorResponse.message);
          userFriendlyMessage = apiErrorResponse.message;
          break;

        case DioExceptionType.cancel:
          apiErrorResponse = _createCancelledErrorResponse(requestId);
          exception = AppException(apiErrorResponse.message);
          userFriendlyMessage = apiErrorResponse.message;
          break;

        case DioExceptionType.connectionError:
          apiErrorResponse = _createConnectionErrorResponse(requestId, err);
          exception = NetworkException(apiErrorResponse.message);
          userFriendlyMessage = apiErrorResponse.message;
          break;

        default:
          apiErrorResponse = _createUnknownErrorResponse(requestId);
          exception = AppException(apiErrorResponse.message);
          userFriendlyMessage = apiErrorResponse.message;
      }
    }

    // Log the error with full context
    _logError(err, exception, apiErrorResponse, requestId);

    // Create enhanced DioException with structured error data
    final enhancedException = DioException(
      requestOptions: err.requestOptions,
      error: exception,
      type: err.type,
      response: err.response,
      message: userFriendlyMessage,
    );

    // Attach the structured error response for client handling
    if (apiErrorResponse != null) {
      enhancedException.requestOptions.extra['apiErrorResponse'] =
          apiErrorResponse;
    }

    handler.reject(enhancedException);
  }

  AppException _createExceptionFromApiError(ApiErrorResponse apiError) {
    switch (apiError.statusCode) {
      case 400:
        return ValidationException(apiError.message);
      case 401:
        return AuthException(apiError.message);
      case 403:
        return AuthException(apiError.message);
      case 404:
        return AppException(apiError.message);
      case 422:
        return ValidationException(apiError.message);
      case 429:
        return NetworkException(apiError.message);
      case 500:
      case 502:
      case 503:
      case 504:
        return ServerException(apiError.message);
      default:
        return AppException(apiError.message);
    }
  }

  AppException _handleStatusCode(
    int? statusCode,
    dynamic data,
    String requestId,
  ) {
    switch (statusCode) {
      case 400:
        return ValidationException(data?['message'] ?? 'Bad request');
      case 401:
        return AuthException('Authentication failed. Please login again.');
      case 403:
        return AuthException(
          'Access denied. You don\'t have permission to perform this action.',
        );
      case 404:
        return const AppException('Resource not found');
      case 422:
        return ValidationException(data?['message'] ?? 'Validation failed');
      case 429:
        return NetworkException(
          'Too many requests. Please wait before trying again.',
        );
      case 500:
        return const ServerException(
          'Internal server error. Please try again later.',
        );
      case 502:
      case 503:
      case 504:
        return const ServerException(
          'Server is temporarily unavailable. Please try again later.',
        );
      default:
        return AppException('Server error (${statusCode ?? 'Unknown'})');
    }
  }

  ApiErrorResponse _createTimeoutErrorResponse(String requestId) {
    return ApiErrorResponse(
      statusCode: 408,
      errorCode: 'REQUEST_TIMEOUT',
      message: 'Request timed out',
      details:
          'The request took too long to complete. This may be due to network connectivity issues or server load.',
      suggestedActions: [
        'Check your internet connection',
        'Try the request again',
        'If the problem persists, contact support',
      ],
      timestamp: DateTime.now().toUtc().toIso8601String(),
      requestId: requestId,
      retryable: true,
    );
  }

  ApiErrorResponse _createCancelledErrorResponse(String requestId) {
    return ApiErrorResponse(
      statusCode: 499,
      errorCode: 'REQUEST_CANCELLED',
      message: 'Request was cancelled',
      details: 'The request was cancelled before it could be completed.',
      suggestedActions: [
        'Try the request again if needed',
        'Ensure you don\'t navigate away while requests are in progress',
      ],
      timestamp: DateTime.now().toUtc().toIso8601String(),
      requestId: requestId,
      retryable: true,
    );
  }

  ApiErrorResponse _createConnectionErrorResponse(
    String requestId,
    DioException err,
  ) {
    String details =
        'Unable to connect to the server. Please check your network connection.';
    List<String> actions = [
      'Check your internet connection',
      'Verify the server URL is correct',
      'Try again in a few moments',
    ];

    // Add specific guidance for Android emulator
    if (err.requestOptions.uri.host == 'localhost' ||
        err.requestOptions.uri.host == '127.0.0.1') {
      details =
          'Cannot connect to localhost. For Android emulator, use 10.0.2.2 instead.';
      actions = [
        'For Android emulator, use 10.0.2.2 instead of localhost',
        'Ensure your backend server is running',
        'Check that the server is bound to 0.0.0.0, not just localhost',
        'Verify the port number is correct',
      ];
    }

    return ApiErrorResponse(
      statusCode: 0, // Network error, no HTTP status
      errorCode: 'CONNECTION_ERROR',
      message: 'Unable to connect to server',
      details: details,
      suggestedActions: actions,
      timestamp: DateTime.now().toUtc().toIso8601String(),
      requestId: requestId,
      context: {
        'host': err.requestOptions.uri.host,
        'port': err.requestOptions.uri.port,
        'scheme': err.requestOptions.uri.scheme,
      },
      retryable: true,
    );
  }

  ApiErrorResponse _createUnknownErrorResponse(String requestId) {
    return ApiErrorResponse(
      statusCode: 0,
      errorCode: 'UNKNOWN_ERROR',
      message: 'An unexpected error occurred',
      details:
          'An unknown network error occurred while processing your request.',
      suggestedActions: [
        'Try the request again',
        'Check your internet connection',
        'If the problem persists, contact support',
      ],
      timestamp: DateTime.now().toUtc().toIso8601String(),
      requestId: requestId,
      retryable: true,
    );
  }

  void _logError(
    DioException err,
    AppException exception,
    ApiErrorResponse? apiErrorResponse,
    String requestId,
  ) {
    AppLogger.error('API Error [Request ID: $requestId]');
    AppLogger.error(
      'URL: ${err.requestOptions.method} ${err.requestOptions.uri}',
    );
    AppLogger.error('Exception: ${exception.message}');

    if (apiErrorResponse != null) {
      AppLogger.error('API Error Response:');
      AppLogger.error('  Status: ${apiErrorResponse.statusCode}');
      AppLogger.error('  Code: ${apiErrorResponse.errorCode}');
      AppLogger.error('  Message: ${apiErrorResponse.message}');
      AppLogger.error('  Details: ${apiErrorResponse.details}');
      AppLogger.error('  Retryable: ${apiErrorResponse.retryable}');

      if (apiErrorResponse.context != null) {
        AppLogger.error('  Context: ${apiErrorResponse.context}');
      }

      if (apiErrorResponse.fieldErrors != null) {
        AppLogger.error('  Field Errors: ${apiErrorResponse.fieldErrors}');
      }
    }

    if (err.response?.data != null) {
      AppLogger.error('Response Data: ${err.response?.data}');
    }
  }
}

/// Global error handler for network errors
class NetworkErrorHandler {
  static void showNetworkError(
    BuildContext context, {
    String? message,
    VoidCallback? onRetry,
    ApiErrorResponse? apiErrorResponse,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NetworkErrorWidget(
          errorMessage: message,
          apiErrorResponse: apiErrorResponse,
          onRetry: () {
            Navigator.of(context).pop();
            onRetry?.call();
          },
        ),
      ),
    );
  }

  /// Extracts ApiErrorResponse from DioException if available
  static ApiErrorResponse? getApiErrorResponse(DioException exception) {
    return exception.requestOptions.extra['apiErrorResponse']
        as ApiErrorResponse?;
  }

  /// Creates a user-friendly error message from any exception
  static String getUserFriendlyMessage(dynamic error) {
    if (error is DioException) {
      final apiError = getApiErrorResponse(error);
      if (apiError != null) {
        return apiError.userFriendlySummary;
      }
    }

    if (error is AppException) {
      return error.message;
    }

    return 'An unexpected error occurred. Please try again.';
  }
}