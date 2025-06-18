// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_code_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QrCodeModel _$QrCodeModelFromJson(Map<String, dynamic> json) => QrCodeModel(
  id: json['id'] as String,
  driver: json['driver'] as String,
  kdVendor: json['kdVendor'] as String,
  content: json['content'] as String,
  size: json['size'] as int,
  errorCorrectionLevel: json['errorCorrectionLevel'] as String,
  foregroundColor: json['foregroundColor'] as String,
  backgroundColor: json['backgroundColor'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$QrCodeModelToJson(QrCodeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'driver': instance.driver,
      'kdVendor': instance.kdVendor,
      'content': instance.content,
      'size': instance.size,
      'errorCorrectionLevel': instance.errorCorrectionLevel,
      'foregroundColor': instance.foregroundColor,
      'backgroundColor': instance.backgroundColor,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
