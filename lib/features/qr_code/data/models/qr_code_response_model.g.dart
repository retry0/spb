// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_code_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QrCodeResponseModel _$QrCodeResponseModelFromJson(Map<String, dynamic> json) =>
    QrCodeResponseModel(
      content: json['content'] as String?,
      success: json['success'] as bool,
      message: json['message'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$QrCodeResponseModelToJson(QrCodeResponseModel instance) =>
    <String, dynamic>{
      'content': instance.content,
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
    };