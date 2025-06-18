import 'package:json_annotation/json_annotation.dart';

part 'qr_code_response_model.g.dart';

@JsonSerializable()
class QrCodeResponseModel {
  final String? content;
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  QrCodeResponseModel({
    this.content,
    required this.success,
    this.message,
    this.data,
  });

  factory QrCodeResponseModel.fromJson(Map<String, dynamic> json) => 
      _$QrCodeResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$QrCodeResponseModelToJson(this);
}