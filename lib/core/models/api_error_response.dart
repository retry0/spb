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

  const ApiErrorResponse({
    required this.statusCode,
    required this.errorCode,
    required this.message,
    required this.details,
    required this.suggestedActions,
    required this.timestamp,
    required this.requestId,
    this.context,
    this.fieldErrors,
    this.documentationUrl,
    this.retryable = false,
  });

  factory ApiErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ApiErrorResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ApiErrorResponseToJson(this);

  @override
  List<Object?> get props => [
    statusCode,
    errorCode,
    message,
    details,
    suggestedActions,
    timestamp,
    requestId,
    context,
    fieldErrors,
    documentationUrl,
    retryable,
  ];

  /// Creates a user-friendly error summary
  String get userFriendlySummary {
    final buffer = StringBuffer();
    buffer.writeln('Error: $message');

    if (suggestedActions.isNotEmpty) {
      buffer.writeln('\nWhat you can do:');
      for (int i = 0; i < suggestedActions.length; i++) {
        buffer.writeln('${i + 1}. ${suggestedActions[i]}');
      }
    }

    if (retryable) {
      buffer.writeln('\nThis operation can be retried.');
    }

    return buffer.toString();
  }

  /// Creates a technical summary for developers
  String get technicalSummary {
    final buffer = StringBuffer();
    buffer.writeln('HTTP $statusCode - $errorCode');
    buffer.writeln('Request ID: $requestId');
    buffer.writeln('Timestamp: $timestamp');
    buffer.writeln('Details: $details');

    if (context != null && context!.isNotEmpty) {
      buffer.writeln('Context: $context');
    }

    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      buffer.writeln('Field Errors:');
      fieldErrors!.forEach((field, errors) {
        buffer.writeln('  $field: ${errors.join(', ')}');
      });
    }

    return buffer.toString();
  }
}
