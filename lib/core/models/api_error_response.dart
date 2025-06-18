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

/// Factory class for creating common API error responses
class ApiErrorResponseFactory {
  /// Creates a validation error response (422)
  static ApiErrorResponse validationError({
    required String requestId,
    required Map<String, List<String>> fieldErrors,
    String? details,
  }) {
    final errorCount = fieldErrors.values.fold(0, (sum, errors) => sum + errors.length);
    
    return ApiErrorResponse(
      statusCode: 422,
      errorCode: 'VALIDATION_ERROR',
      message: 'The request contains invalid data',
      details: details ?? 'Validation failed for $errorCount field(s). Please check the field errors for specific issues.',
      suggestedActions: [
        'Review the field errors below and correct the invalid data',
        'Ensure all required fields are provided',
        'Check that field values match the expected format and constraints',
        'Refer to the API documentation for field requirements',
      ],
      timestamp: DateTime.now().toUtc().toIso8601String(),
      requestId: requestId,
      fieldErrors: fieldErrors,
      documentationUrl: 'https://api-docs.spb-secure.com/validation-errors',
      retryable: false,
    );
  }

  /// Creates an authentication error response (401)
  static ApiErrorResponse authenticationError({
    required String requestId,
    String? details,
  }) {
    return ApiErrorResponse(
      statusCode: 401,
      errorCode: 'AUTHENTICATION_REQUIRED',
      message: 'Authentication is required to access this resource',
      details: details ?? 'The request lacks valid authentication credentials. The access token may be missing, expired, or invalid.',
      suggestedActions: [
        'Ensure you are logged in with valid credentials',
        'Check that your access token is included in the Authorization header',
        'Verify that your access token has not expired',
        'If the token is expired, obtain a new one by logging in again',
      ],
      timestamp: DateTime.now().toUtc().toIso8601String(),
      requestId: requestId,
      context: {
        'authenticationMethod': 'Bearer Token',
        'tokenLocation': 'Authorization Header',
      },
      documentationUrl: 'https://api-docs.spb-secure.com/authentication',
      retryable: true,
    );
  }

  /// Creates an authorization error response (403)
  static ApiErrorResponse authorizationError({
    required String requestId,
    required String resource,
    required String action,
    List<String>? requiredPermissions,
  }) {
    return ApiErrorResponse(
      statusCode: 403,
      errorCode: 'INSUFFICIENT_PERMISSIONS',
      message: 'You do not have permission to perform this action',
      details: 'Access denied for $action on $resource. Your account lacks the necessary permissions to complete this request.',
      suggestedActions: [
        'Contact your administrator to request the necessary permissions',
        'Verify that you are accessing the correct resource',
        'Check if your account has the required role or permissions',
        'Ensure you are logged in with the correct user account',
      ],
      timestamp: DateTime.now().toUtc().toIso8601String(),
      requestId: requestId,
      context: {
        'resource': resource,
        'action': action,
        'requiredPermissions': requiredPermissions,
      },
      documentationUrl: 'https://api-docs.spb-secure.com/permissions',
      retryable: false,
    );
  }

  /// Creates a not found error response (404)
  static ApiErrorResponse notFoundError({
    required String requestId,
    required String resourceType,
    required String resourceId,
  }) {
    return ApiErrorResponse(
      statusCode: 404,
      errorCode: 'RESOURCE_NOT_FOUND',
      message: 'The requested resource could not be found',
      details: 'The $resourceType with ID "$resourceId" does not exist or has been deleted.',
      suggestedActions: [
        'Verify that the resource ID is correct',
        'Check if the resource has been moved or deleted',
        'Ensure you have permission to access this resource',
        'Try searching for the resource using different criteria',
      ],
      timestamp: DateTime.now().toUtc().toIso8601String(),
      requestId: requestId,
      context: {
        'resourceType': resourceType,
        'resourceId': resourceId,
      },
      documentationUrl: 'https://api-docs.spb-secure.com/resources',
      retryable: false,
    );
  }

  /// Creates a rate limit error response (429)
  static ApiErrorResponse rateLimitError({
    required String requestId,
    required int retryAfterSeconds,
    required int requestsPerWindow,
    required String windowDuration,
  }) {
    return ApiErrorResponse(
      statusCode: 429,
      errorCode: 'RATE_LIMIT_EXCEEDED',
      message: 'Too many requests - rate limit exceeded',
      details: 'You have exceeded the rate limit of $requestsPerWindow requests per $windowDuration. Please wait before making additional requests.',
      suggestedActions: [
        'Wait $retryAfterSeconds seconds before retrying',
        'Implement exponential backoff in your client',
        'Reduce the frequency of your API requests',
        'Consider upgrading your plan for higher rate limits',
        'Use batch operations where available to reduce request count',
      ],
      timestamp: DateTime.now().toUtc().toIso8601String(),
      requestId: requestId,
      context: {
        'retryAfterSeconds': retryAfterSeconds,
        'requestsPerWindow': requestsPerWindow,
        'windowDuration': windowDuration,
        'retryAfter': DateTime.now().add(Duration(seconds: retryAfterSeconds)).toUtc().toIso8601String(),
      },
      documentationUrl: 'https://api-docs.spb-secure.com/rate-limits',
      retryable: true,
    );
  }

  /// Creates a server error response (500)
  static ApiErrorResponse serverError({
    required String requestId,
    String? details,
    String? errorId,
  }) {
    return ApiErrorResponse(
      statusCode: 500,
      errorCode: 'INTERNAL_SERVER_ERROR',
      message: 'An unexpected server error occurred',
      details: details ?? 'The server encountered an unexpected condition that prevented it from fulfilling the request. Our team has been notified.',
      suggestedActions: [
        'Try the request again in a few moments',
        'If the problem persists, contact our support team',
        'Include the request ID when reporting this issue',
        'Check our status page for any ongoing service issues',
      ],
      timestamp: DateTime.now().toUtc().toIso8601String(),
      requestId: requestId,
      context: {
        'errorId': errorId,
        'supportContact': 'support@spb-secure.com',
        'statusPage': 'https://status.spb-secure.com',
      },
      documentationUrl: 'https://api-docs.spb-secure.com/errors',
      retryable: true,
    );
  }

  /// Creates a service unavailable error response (503)
  static ApiErrorResponse serviceUnavailableError({
    required String requestId,
    int? retryAfterSeconds,
    String? reason,
  }) {
    return ApiErrorResponse(
      statusCode: 503,
      errorCode: 'SERVICE_UNAVAILABLE',
      message: 'Service temporarily unavailable',
      details: reason ?? 'The service is temporarily unavailable due to maintenance or high load. Please try again later.',
      suggestedActions: [
        retryAfterSeconds != null 
            ? 'Wait at least $retryAfterSeconds seconds before retrying'
            : 'Wait a few minutes before retrying',
        'Implement exponential backoff for automatic retries',
        'Check our status page for maintenance announcements',
        'Contact support if the issue persists for an extended period',
      ],
      timestamp: DateTime.now().toUtc().toIso8601String(),
      requestId: requestId,
      context: {
        'retryAfterSeconds': retryAfterSeconds,
        'reason': reason,
        'statusPage': 'https://status.spb-secure.com',
      },
      documentationUrl: 'https://api-docs.spb-secure.com/service-availability',
      retryable: true,
    );
  }
}