// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_error_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiErrorResponse _$ApiErrorResponseFromJson(Map<String, dynamic> json) =>
    ApiErrorResponse(
      statusCode: (json['statusCode'] as num).toInt(),
      errorCode: json['errorCode'] as String,
      message: json['message'] as String,
      details: json['details'] as String,
      suggestedActions: (json['suggestedActions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      timestamp: json['timestamp'] as String,
      requestId: json['requestId'] as String,
      context: json['context'] as Map<String, dynamic>?,
      fieldErrors: (json['fieldErrors'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      ),
      documentationUrl: json['documentationUrl'] as String?,
      retryable: json['retryable'] as bool? ?? false,
    );

Map<String, dynamic> _$ApiErrorResponseToJson(ApiErrorResponse instance) =>
    <String, dynamic>{
      'statusCode': instance.statusCode,
      'errorCode': instance.errorCode,
      'message': instance.message,
      'details': instance.details,
      'suggestedActions': instance.suggestedActions,
      'timestamp': instance.timestamp,
      'requestId': instance.requestId,
      'context': instance.context,
      'fieldErrors': instance.fieldErrors,
      'documentationUrl': instance.documentationUrl,
      'retryable': instance.retryable,
    };
