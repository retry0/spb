import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/qr_code.dart';
import '../../domain/usecases/generate_qr_code_usecase.dart';
import '../../domain/usecases/save_qr_code_usecase.dart';
import '../../domain/usecases/get_saved_qr_codes_usecase.dart';
import '../../domain/usecases/export_qr_code_usecase.dart';
import '../../domain/usecases/share_qr_code_usecase.dart';

part 'qr_code_event.dart';
part 'qr_code_state.dart';

class QrCodeBloc extends Bloc<QrCodeEvent, QrCodeState> {
  final GenerateQrCodeUseCase _generateQrCodeUseCase;
  final SaveQrCodeUseCase _saveQrCodeUseCase;
  final GetSavedQrCodesUseCase _getSavedQrCodesUseCase;
  final ExportQrCodeUseCase _exportQrCodeUseCase;
  final ShareQrCodeUseCase _shareQrCodeUseCase;

  QrCodeBloc({
    required GenerateQrCodeUseCase generateQrCodeUseCase,
    required SaveQrCodeUseCase saveQrCodeUseCase,
    required GetSavedQrCodesUseCase getSavedQrCodesUseCase,
    required ExportQrCodeUseCase exportQrCodeUseCase,
    required ShareQrCodeUseCase shareQrCodeUseCase,
  })  : _generateQrCodeUseCase = generateQrCodeUseCase,
        _saveQrCodeUseCase = saveQrCodeUseCase,
        _getSavedQrCodesUseCase = getSavedQrCodesUseCase,
        _exportQrCodeUseCase = exportQrCodeUseCase,
        _shareQrCodeUseCase = shareQrCodeUseCase,
        super(QrCodeInitial()) {
    on<GenerateQrCodeRequested>(_onGenerateQrCodeRequested);
    on<SaveQrCodeRequested>(_onSaveQrCodeRequested);
    on<LoadSavedQrCodesRequested>(_onLoadSavedQrCodesRequested);
    on<ExportQrCodeRequested>(_onExportQrCodeRequested);
    on<ShareQrCodeRequested>(_onShareQrCodeRequested);
    on<QrCodeSizeChanged>(_onQrCodeSizeChanged);
    on<QrCodeErrorCorrectionChanged>(_onQrCodeErrorCorrectionChanged);
    on<QrCodeThemeChanged>(_onQrCodeThemeChanged);
    on<ClearCurrentQrCode>(_onClearCurrentQrCode);
  }

  Future<void> _onGenerateQrCodeRequested(
    GenerateQrCodeRequested event,
    Emitter<QrCodeState> emit,
  ) async {
    emit(QrCodeGenerating());

    final result = await _generateQrCodeUseCase(
      driver: event.driver,
      kdVendor: event.kdVendor,
      size: event.size,
      errorCorrectionLevel: event.errorCorrectionLevel,
      foregroundColor: event.foregroundColor,
      backgroundColor: event.backgroundColor,
    );

    await result.fold(
      (failure) async {
        emit(QrCodeGenerationFailure(failure.message));
      },
      (qrCode) async {
        emit(QrCodeGenerated(qrCode));
      },
    );
  }

  Future<void> _onSaveQrCodeRequested(
    SaveQrCodeRequested event,
    Emitter<QrCodeState> emit,
  ) async {
    final currentState = state;
    if (currentState is QrCodeGenerated) {
      emit(QrCodeSaving());

      final result = await _saveQrCodeUseCase(currentState.qrCode);

      await result.fold(
        (failure) async {
          emit(QrCodeSaveFailure(failure.message));
          emit(currentState); // Restore previous state
        },
        (success) async {
          emit(QrCodeSaved(currentState.qrCode));
          
          // Reload saved QR codes
          add(const LoadSavedQrCodesRequested());
        },
      );
    }
  }

  Future<void> _onLoadSavedQrCodesRequested(
    LoadSavedQrCodesRequested event,
    Emitter<QrCodeState> emit,
  ) async {
    emit(QrCodeLoading());

    final result = await _getSavedQrCodesUseCase();

    await result.fold(
      (failure) async {
        emit(QrCodeLoadFailure(failure.message));
      },
      (qrCodes) async {
        emit(QrCodeLoaded(qrCodes));
      },
    );
  }

  Future<void> _onExportQrCodeRequested(
    ExportQrCodeRequested event,
    Emitter<QrCodeState> emit,
  ) async {
    final currentState = state;
    QrCode qrCode;
    
    if (currentState is QrCodeGenerated) {
      qrCode = currentState.qrCode;
    } else if (currentState is QrCodeSaved) {
      qrCode = currentState.qrCode;
    } else {
      emit(const QrCodeExportFailure('No QR code available to export'));
      return;
    }
    
    emit(QrCodeExporting());

    final result = await _exportQrCodeUseCase(
      qrCode: qrCode,
      format: event.format,
      size: event.size,
    );

    await result.fold(
      (failure) async {
        emit(QrCodeExportFailure(failure.message));
        // Restore previous state
        if (currentState is QrCodeGenerated) {
          emit(QrCodeGenerated(qrCode));
        } else if (currentState is QrCodeSaved) {
          emit(QrCodeSaved(qrCode));
        }
      },
      (filePath) async {
        emit(QrCodeExported(qrCode, filePath));
        // Restore previous state after a delay
        await Future.delayed(const Duration(seconds: 2));
        if (currentState is QrCodeGenerated) {
          emit(QrCodeGenerated(qrCode));
        } else if (currentState is QrCodeSaved) {
          emit(QrCodeSaved(qrCode));
        }
      },
    );
  }

  Future<void> _onShareQrCodeRequested(
    ShareQrCodeRequested event,
    Emitter<QrCodeState> emit,
  ) async {
    final currentState = state;
    QrCode qrCode;
    
    if (currentState is QrCodeGenerated) {
      qrCode = currentState.qrCode;
    } else if (currentState is QrCodeSaved) {
      qrCode = currentState.qrCode;
    } else {
      emit(const QrCodeShareFailure('No QR code available to share'));
      return;
    }
    
    emit(QrCodeSharing());

    final result = await _shareQrCodeUseCase(
      qrCode: qrCode,
      format: event.format,
      size: event.size,
    );

    await result.fold(
      (failure) async {
        emit(QrCodeShareFailure(failure.message));
        // Restore previous state
        if (currentState is QrCodeGenerated) {
          emit(QrCodeGenerated(qrCode));
        } else if (currentState is QrCodeSaved) {
          emit(QrCodeSaved(qrCode));
        }
      },
      (success) async {
        emit(QrCodeShared());
        // Restore previous state after a delay
        await Future.delayed(const Duration(seconds: 1));
        if (currentState is QrCodeGenerated) {
          emit(QrCodeGenerated(qrCode));
        } else if (currentState is QrCodeSaved) {
          emit(QrCodeSaved(qrCode));
        }
      },
    );
  }

  void _onQrCodeSizeChanged(
    QrCodeSizeChanged event,
    Emitter<QrCodeState> emit,
  ) {
    final currentState = state;
    if (currentState is QrCodeGenerated) {
      final updatedQrCode = currentState.qrCode.copyWith(
        size: event.size,
        updatedAt: DateTime.now(),
      );
      emit(QrCodeGenerated(updatedQrCode));
    }
  }

  void _onQrCodeErrorCorrectionChanged(
    QrCodeErrorCorrectionChanged event,
    Emitter<QrCodeState> emit,
  ) {
    final currentState = state;
    if (currentState is QrCodeGenerated) {
      final updatedQrCode = currentState.qrCode.copyWith(
        errorCorrectionLevel: event.errorCorrectionLevel,
        updatedAt: DateTime.now(),
      );
      emit(QrCodeGenerated(updatedQrCode));
    }
  }

  void _onQrCodeThemeChanged(
    QrCodeThemeChanged event,
    Emitter<QrCodeState> emit,
  ) {
    final currentState = state;
    if (currentState is QrCodeGenerated) {
      final updatedQrCode = currentState.qrCode.copyWith(
        foregroundColor: event.foregroundColor,
        backgroundColor: event.backgroundColor,
        updatedAt: DateTime.now(),
      );
      emit(QrCodeGenerated(updatedQrCode));
    }
  }

  void _onClearCurrentQrCode(
    ClearCurrentQrCode event,
    Emitter<QrCodeState> emit,
  ) {
    emit(QrCodeInitial());
  }
}