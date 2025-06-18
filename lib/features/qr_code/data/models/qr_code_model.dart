import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/qr_code.dart';

part 'qr_code_model.g.dart';

@JsonSerializable()
class QrCodeModel extends QrCode {
  const QrCodeModel({
    required super.id,
    required super.driver,
    required super.kdVendor,
    required super.content,
    required super.size,
    required super.errorCorrectionLevel,
    required super.foregroundColor,
    required super.backgroundColor,
    required super.createdAt,
    required super.updatedAt,
  });

  factory QrCodeModel.fromJson(Map<String, dynamic> json) => _$QrCodeModelFromJson(json);

  Map<String, dynamic> toJson() => _$QrCodeModelToJson(this);

  factory QrCodeModel.fromEntity(QrCode qrCode) {
    return QrCodeModel(
      id: qrCode.id,
      driver: qrCode.driver,
      kdVendor: qrCode.kdVendor,
      content: qrCode.content,
      size: qrCode.size,
      errorCorrectionLevel: qrCode.errorCorrectionLevel,
      foregroundColor: qrCode.foregroundColor,
      backgroundColor: qrCode.backgroundColor,
      createdAt: qrCode.createdAt,
      updatedAt: qrCode.updatedAt,
    );
  }

  factory QrCodeModel.fromDatabase(Map<String, dynamic> data) {
    return QrCodeModel(
      id: data['id'] as String,
      driver: data['driver'] as String,
      kdVendor: data['kd_vendor'] as String,
      content: data['content'] as String,
      size: data['size'] as int,
      errorCorrectionLevel: data['error_correction_level'] as String,
      foregroundColor: data['foreground_color'] as String,
      backgroundColor: data['background_color'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(data['updated_at'] as int),
    );
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'driver': driver,
      'kd_vendor': kdVendor,
      'content': content,
      'size': size,
      'error_correction_level': errorCorrectionLevel,
      'foreground_color': foregroundColor,
      'background_color': backgroundColor,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }
}