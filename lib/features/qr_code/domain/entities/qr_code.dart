import 'package:equatable/equatable.dart';

/// QR Code entity representing a generated QR code
class QrCode extends Equatable {
  /// Unique identifier for the QR code
  final String id;
  
  /// Driver information from UserModel
  final String driver;
  
  /// Vendor information from UserModel
  final String kdVendor;
  
  /// QR code content (encoded data)
  final String content;
  
  /// QR code size (width/height in pixels)
  final int size;
  
  /// Error correction level (L, M, Q, H)
  final String errorCorrectionLevel;
  
  /// Foreground color (hex string)
  final String foregroundColor;
  
  /// Background color (hex string)
  final String backgroundColor;
  
  /// Creation timestamp
  final DateTime createdAt;
  
  /// Last modified timestamp
  final DateTime updatedAt;

  const QrCode({
    required this.id,
    required this.driver,
    required this.kdVendor,
    required this.content,
    required this.size,
    required this.errorCorrectionLevel,
    required this.foregroundColor,
    required this.backgroundColor,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this QR code with the given fields replaced with new values
  QrCode copyWith({
    String? id,
    String? driver,
    String? kdVendor,
    String? content,
    int? size,
    String? errorCorrectionLevel,
    String? foregroundColor,
    String? backgroundColor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QrCode(
      id: id ?? this.id,
      driver: driver ?? this.driver,
      kdVendor: kdVendor ?? this.kdVendor,
      content: content ?? this.content,
      size: size ?? this.size,
      errorCorrectionLevel: errorCorrectionLevel ?? this.errorCorrectionLevel,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    driver,
    kdVendor,
    content,
    size,
    errorCorrectionLevel,
    foregroundColor,
    backgroundColor,
    createdAt,
    updatedAt,
  ];
}