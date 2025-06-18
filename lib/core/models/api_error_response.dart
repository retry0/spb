import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';

part 'api_error_response.g.dart';

/// Professional REST API error response model following industry best practices
@JsonSerializable()
class ApiErrorResponse extends Equatable {
  /// HTTP status code
  final int statusCode;

  /// Application-specific error code for programmatic handling
  final String errorCode;

  /// Human-readable error message
  final String message;

  /// Detailed technical description for developers
  final String details;

  /// Suggested actions to resolve the issue
  final List<String> suggestedActions;

  /// ISO 8601 timestamp when the error occurred
  final String timestamp;

  /// Unique request identifier for tracking and debugging
  final String requestId;

  /// Additional context or metadata about the error
  final Map<String, dynamic>? context;

  /// Field-specific validation errors (for 422 responses)
  final Map<String, List<String>>? fieldErrors;

  /// Link to documentation or help resources
  final String? documentationUrl;

  /// Whether this error can be retried
  final bool retryable;

  class ApiErrorResponse {
  final int statusCode;
  final String errorCode;
  final String message;
  final String? details;
  final List<String>? suggestedActions;
  final String? timestamp;
  final String? requestId;
  final bool? retryable;
  final Map<String, dynamic>? context;
  final Map<String, dynamic>? fieldErrors;

  ApiErrorResponse({
    required this.statusCode,
    required this.errorCode,
    required this.message,
    this.details,
    this.suggestedActions,
    this.timestamp,
    this.requestId,
    this.retryable,
    this.context,
    this.fieldErrors,
  });

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) {
    return ApiErrorResponse(
      statusCode: json['statusCode'] ?? 0,
      errorCode: json['errorCode'] ?? '',
      message: json['message'] ?? '',
      details: json['details'],
      suggestedActions: (json['suggestedActions'] as List?)?.cast<String>(),
      timestamp: json['timestamp'],
      requestId: json['requestId'],
      retryable: json['retryable'],
      context: json['context'] as Map<String, dynamic>?,
      fieldErrors: json['fieldErrors'] as Map<String, dynamic>?,
    );
  }

  String get userFriendlySummary => message;
}
}