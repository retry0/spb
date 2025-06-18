part of 'qr_code_bloc.dart';

abstract class QrCodeEvent extends Equatable {
  const QrCodeEvent();

  @override
  List<Object?> get props => [];
}

class GenerateQrCodeRequested extends QrCodeEvent {
  final String driver;
  final String kdVendor;
  final int size;
  final String errorCorrectionLevel;
  final String? foregroundColor;
  final String? backgroundColor;

  const GenerateQrCodeRequested({
    required this.driver,
    required this.kdVendor,
    this.size = 300,
    this.errorCorrectionLevel = 'M',
    this.foregroundColor,
    this.backgroundColor,
  });

  @override
  List<Object?> get props => [
    driver,
    kdVendor,
    size,
    errorCorrectionLevel,
    foregroundColor,
    backgroundColor,
  ];
}

class SaveQrCodeRequested extends QrCodeEvent {
  const SaveQrCodeRequested();
}

class LoadSavedQrCodesRequested extends QrCodeEvent {
  const LoadSavedQrCodesRequested();
}

class ExportQrCodeRequested extends QrCodeEvent {
  final String format;
  final int size;

  const ExportQrCodeRequested({
    this.format = 'png',
    this.size = 1024,
  });

  @override
  List<Object> get props => [format, size];
}

class ShareQrCodeRequested extends QrCodeEvent {
  final String format;
  final int size;

  const ShareQrCodeRequested({
    this.format = 'png',
    this.size = 800,
  });

  @override
  List<Object> get props => [format, size];
}

class QrCodeSizeChanged extends QrCodeEvent {
  final int size;

  const QrCodeSizeChanged(this.size);

  @override
  List<Object> get props => [size];
}

class QrCodeErrorCorrectionChanged extends QrCodeEvent {
  final String errorCorrectionLevel;

  const QrCodeErrorCorrectionChanged(this.errorCorrectionLevel);

  @override
  List<Object> get props => [errorCorrectionLevel];
}

class QrCodeThemeChanged extends QrCodeEvent {
  final String foregroundColor;
  final String backgroundColor;

  const QrCodeThemeChanged({
    required this.foregroundColor,
    required this.backgroundColor,
  });

  @override
  List<Object> get props => [foregroundColor, backgroundColor];
}

class ClearCurrentQrCode extends QrCodeEvent {
  const ClearCurrentQrCode();
}