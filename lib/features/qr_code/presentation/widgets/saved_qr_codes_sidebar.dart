import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

import '../bloc/qr_code_bloc.dart';

class SavedQrCodesSidebar extends StatelessWidget {
  const SavedQrCodesSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(-5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Saved QR Codes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                BlocBuilder<QrCodeBloc, QrCodeState>(
                  builder: (context, state) {
                    if (state is QrCodeLoaded) {
                      return Text(
                        '${state.qrCodes.length} codes',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: BlocBuilder<QrCodeBloc, QrCodeState>(
              builder: (context, state) {
                if (state is QrCodeLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is QrCodeLoaded) {
                  if (state.qrCodes.isEmpty) {
                    return _buildEmptyState(context);
                  }
                  return _buildQrCodesList(context, state);
                } else if (state is QrCodeLoadFailure) {
                  return _buildErrorState(context, state.message);
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_2, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Saved QR Codes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Generate and save QR codes to see them here',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading QR Codes',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.read<QrCodeBloc>().add(
                  const LoadSavedQrCodesRequested(),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrCodesList(BuildContext context, QrCodeLoaded state) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: state.qrCodes.length,
      itemBuilder: (context, index) {
        final qrCode = state.qrCodes[index];
        return _SavedQrCodeItem(qrCode: qrCode);
      },
    );
  }
}

class _SavedQrCodeItem extends StatelessWidget {
  final dynamic qrCode;

  const _SavedQrCodeItem({required this.qrCode});

  @override
  Widget build(BuildContext context) {
    // Convert hex color strings to Color objects
    final foregroundColor = _hexToColor(qrCode.foregroundColor);
    final backgroundColor = _hexToColor(qrCode.backgroundColor);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // Load this QR code
          context.read<QrCodeBloc>().add(
            GenerateQrCodeRequested(
              driver: qrCode.driver,
              kdVendor: qrCode.kdVendor,
              size: qrCode.size,
              errorCorrectionLevel: qrCode.errorCorrectionLevel,
              foregroundColor: qrCode.foregroundColor,
              backgroundColor: qrCode.backgroundColor,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // QR code thumbnail
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(4),
                child: QrImageView(
                  data: qrCode.content,
                  version: QrVersions.auto,
                  size: 52,
                  backgroundColor: backgroundColor,
                  foregroundColor: foregroundColor,
                  errorCorrectionLevel: _getErrorCorrectionLevel(
                    qrCode.errorCorrectionLevel,
                  ),
                  gapless: true,
                ),
              ),
              const SizedBox(width: 12),

              // QR code details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver: ${qrCode.driver}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Vendor: ${qrCode.kdVendor}',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Created: ${DateFormat('MMM d, yyyy').format(qrCode.createdAt)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Actions
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  context.read<QrCodeBloc>().add(
                    ShareQrCodeRequested(format: 'png', size: 800),
                  );
                },
                tooltip: 'Share',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to convert hex string to Color
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
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
}
