part of 'qr_code_bloc.dart';

abstract class QrCodeState extends Equatable {
  const QrCodeState();

  @override
  List<Object?> get props => [];
}

class QrCodeInitial extends QrCodeState {}

class QrCodeGenerating extends QrCodeState {}

class QrCodeGenerated extends QrCodeState {
  final QrCode qrCode;

  const QrCodeGenerated(this.qrCode);

  @override
  List<Object> get props => [qrCode];
}

class QrCodeGenerationFailure extends QrCodeState {
  final String message;

  const QrCodeGenerationFailure(this.message);

  @override
  List<Object> get props => [message];
}

class QrCodeSaving extends QrCodeState {}

class QrCodeSaved extends QrCodeState {
  final QrCode qrCode;

  const QrCodeSaved(this.qrCode);

  @override
  List<Object> get props => [qrCode];
}

class QrCodeSaveFailure extends QrCodeState {
  final String message;

  const QrCodeSaveFailure(this.message);

  @override
  List<Object> get props => [message];
}

class QrCodeLoading extends QrCodeState {}

class QrCodeLoaded extends QrCodeState {
  final List<QrCode> qrCodes;

  const QrCodeLoaded(this.qrCodes);

  @override
  List<Object> get props => [qrCodes];
}

class QrCodeLoadFailure extends QrCodeState {
  final String message;

  const QrCodeLoadFailure(this.message);

  @override
  List<Object> get props => [message];
}

class QrCodeExporting extends QrCodeState {}

class QrCodeExported extends QrCodeState {
  final QrCode qrCode;
  final String filePath;

  const QrCodeExported(this.qrCode, this.filePath);

  @override
  List<Object> get props => [qrCode, filePath];
}

class QrCodeExportFailure extends QrCodeState {
  final String message;

  const QrCodeExportFailure(this.message);

  @override
  List<Object> get props => [message];
}

class QrCodeSharing extends QrCodeState {}

class QrCodeShared extends QrCodeState {}

class QrCodeShareFailure extends QrCodeState {
  final String message;

  const QrCodeShareFailure(this.message);

  @override
  List<Object> get props => [message];
}