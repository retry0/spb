import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/database_helper.dart';
import '../models/qr_code_model.dart';

abstract class QrCodeLocalDataSource {
  /// Save a QR code to local storage
  Future<bool> saveQrCode(QrCodeModel qrCode);

  /// Get all saved QR codes
  Future<List<QrCodeModel>> getSavedQrCodes();

  /// Get a specific QR code by ID
  Future<QrCodeModel> getQrCodeById(String id);

  /// Delete a QR code from storage
  Future<bool> deleteQrCode(String id);

  /// Get the total storage usage for QR codes in bytes
  Future<int> getStorageUsage();

  /// Check if the storage is nearing capacity (80% threshold)
  Future<bool> isStorageNearingCapacity();

  /// Export a QR code as an image file
  Future<String> exportQrCodeAsImage(
    QrCodeModel qrCode,
    String format,
    int size,
  );

  /// Share a QR code
  Future<bool> shareQrCode(QrCodeModel qrCode, String format, int size);
}

class QrCodeLocalDataSourceImpl implements QrCodeLocalDataSource {
  final DatabaseHelper _dbHelper;
  final SharedPreferences _prefs;

  // Constants
  static const int _maxQrCodes = 50;
  static const int _maxStorageBytes = 10 * 1024 * 1024; // 10MB
  static const double _storageThreshold = 0.8; // 80%

  QrCodeLocalDataSourceImpl({
    required DatabaseHelper dbHelper,
    required SharedPreferences prefs,
  }) : _dbHelper = dbHelper,
       _prefs = prefs;

  @override
  Future<bool> saveQrCode(QrCodeModel qrCode) async {
    try {
      // Check if we've reached the maximum number of QR codes
      final qrCodes = await getSavedQrCodes();
      if (qrCodes.length >= _maxQrCodes) {
        throw CacheException('Maximum number of saved QR codes reached (50)');
      }

      // Save to database
      await _dbHelper.insert('qr_codes', qrCode.toDatabase());

      // Update storage usage
      await _updateStorageUsage();

      return true;
    } catch (e) {
      throw CacheException('Failed to save QR code: $e');
    }
  }

  @override
  Future<List<QrCodeModel>> getSavedQrCodes() async {
    try {
      final results = await _dbHelper.query(
        'qr_codes',
        orderBy: 'created_at DESC',
      );

      return results.map((data) => QrCodeModel.fromDatabase(data)).toList();
    } catch (e) {
      throw CacheException('Failed to get saved QR codes: $e');
    }
  }

  @override
  Future<QrCodeModel> getQrCodeById(String id) async {
    try {
      final results = await _dbHelper.query(
        'qr_codes',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) {
        throw CacheException('QR code not found with ID: $id');
      }

      return QrCodeModel.fromDatabase(results.first);
    } catch (e) {
      throw CacheException('Failed to get QR code by ID: $e');
    }
  }

  @override
  Future<bool> deleteQrCode(String id) async {
    try {
      final result = await _dbHelper.delete(
        'qr_codes',
        where: 'id = ?',
        whereArgs: [id],
      );

      // Update storage usage
      await _updateStorageUsage();

      return result > 0;
    } catch (e) {
      throw CacheException('Failed to delete QR code: $e');
    }
  }

  @override
  Future<int> getStorageUsage() async {
    try {
      // Get current storage usage from preferences
      return _prefs.getInt('qr_code_storage_usage') ?? 0;
    } catch (e) {
      throw CacheException('Failed to get storage usage: $e');
    }
  }

  @override
  Future<bool> isStorageNearingCapacity() async {
    try {
      final usage = await getStorageUsage();
      return usage > (_maxStorageBytes * _storageThreshold);
    } catch (e) {
      throw CacheException('Failed to check storage capacity: $e');
    }
  }

  @override
  Future<String> exportQrCodeAsImage(
    QrCodeModel qrCode,
    String format,
    int size,
  ) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw PermissionException('Storage permission not granted');
      }

      // Generate QR code image
      final qrImage = await _generateQrImage(qrCode, size);

      // Save to gallery using image_gallery_saver_plus
      final result = await ImageGallerySaverPlus.saveImage(
        qrImage,
        quality: 100,
        name: 'QR_${qrCode.id}_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result['isSuccess']) {
        return result['filePath'] ?? 'Image saved to gallery';
      } else {
        throw CacheException(
          'Failed to save image to gallery: ${result['errorMessage']}',
        );
      }
    } catch (e) {
      throw CacheException('Failed to export QR code as image: $e');
    }
  }

  @override
  Future<bool> shareQrCode(QrCodeModel qrCode, String format, int size) async {
    try {
      // Generate QR code image
      final qrImage = await _generateQrImage(qrCode, size);

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/qr_${qrCode.id}.png';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(qrImage);

      // Share the file
      await Share.shareXFiles([
        XFile(tempPath),
      ], text: 'QR Code for ${qrCode.driver}');

      return true;
    } catch (e) {
      throw CacheException('Failed to share QR code: $e');
    }
  }

  // Helper method to generate QR code image
  Future<Uint8List> _generateQrImage(QrCodeModel qrCode, int size) async {
    try {
      // Create QR painter
      final qrPainter = QrPainter(
        data: qrCode.content,
        version: QrVersions.auto,
        errorCorrectionLevel: _getErrorCorrectionLevel(
          qrCode.errorCorrectionLevel,
        ),
        color: _hexToColor(qrCode.foregroundColor),
        emptyColor: _hexToColor(qrCode.backgroundColor),
        gapless: true,
      );

      // Create a square canvas
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..color = _hexToColor(qrCode.backgroundColor);

      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
        paint,
      );

      // Draw QR code
      qrPainter.paint(canvas, Size(size.toDouble(), size.toDouble()));
      final picture = recorder.endRecording();

      // Convert to image
      final img = await picture.toImage(size, size);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

      return byteData!.buffer.asUint8List();
    } catch (e) {
      throw CacheException('Failed to generate QR image: $e');
    }
  }

  // Helper method to update storage usage
  Future<void> _updateStorageUsage() async {
    try {
      // Calculate storage usage
      final qrCodes = await getSavedQrCodes();
      int totalBytes = 0;

      for (final qrCode in qrCodes) {
        // Estimate size based on content length and metadata
        final contentBytes = utf8.encode(qrCode.content).length;
        final metadataBytes = utf8.encode(json.encode(qrCode.toJson())).length;
        totalBytes += contentBytes + metadataBytes;
      }

      // Save to preferences
      await _prefs.setInt('qr_code_storage_usage', totalBytes);
    } catch (e) {
      // Log error but don't throw
      print('Failed to update storage usage: $e');
    }
  }

  // Helper method to convert error correction level string to enum
  int _getErrorCorrectionLevel(String level) {
    switch (level) {
      case 'L':
        return QrErrorCorrectLevel.L;
      case 'M':
        return QrErrorCorrectLevel.M;
      case 'Q':
        return QrErrorCorrectLevel.Q;
      case 'H':
        return QrErrorCorrectLevel.H;
      default:
        return QrErrorCorrectLevel.M;
    }
  }

  // Helper method to convert hex string to Color
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
