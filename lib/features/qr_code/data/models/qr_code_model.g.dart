// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qr_code_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QrCodeModel _$QrCodeModelFromJson(Map<String, dynamic> json) => QrCodeModel(
<<<<<<< HEAD
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
=======
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
>>>>>>> 6104a00abfa2e7e5ed866e59bda3f67b5e38015d

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
<<<<<<< HEAD
    };
=======
    };
>>>>>>> 6104a00abfa2e7e5ed866e59bda3f67b5e38015d
