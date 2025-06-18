import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/qr_code_bloc.dart';

class QrCodeActionButtons extends StatelessWidget {
  const QrCodeActionButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<QrCodeBloc, QrCodeState>(
      builder: (context, state) {
        final bool hasQrCode = state is QrCodeGenerated || state is QrCodeSaved;
        final bool isSaved = state is QrCodeSaved;
        
        if (!hasQrCode) {
          return const SizedBox.shrink();
        }
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Save button
                    if (!isSaved)
                      _ActionButton(
                        icon: Icons.save,
                        label: 'Save',
                        onPressed: () {
                          context.read<QrCodeBloc>().add(const SaveQrCodeRequested());
                        },
                        isLoading: state is QrCodeSaving,
                      ),
                    
                    // Export button
                    _ActionButton(
                      icon: Icons.download,
                      label: 'Export',
                      onPressed: () {
                        _showExportDialog(context);
                      },
                      isLoading: state is QrCodeExporting,
                    ),
                    
                    // Share button
                    _ActionButton(
                      icon: Icons.share,
                      label: 'Share',
                      onPressed: () {
                        context.read<QrCodeBloc>().add(const ShareQrCodeRequested());
                      },
                      isLoading: state is QrCodeSharing,
                    ),
                    
                    // Clear button
                    _ActionButton(
                      icon: Icons.delete,
                      label: 'Clear',
                      onPressed: () {
                        context.read<QrCodeBloc>().add(const ClearCurrentQrCode());
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _showExportDialog(BuildContext context) {
    String selectedFormat = 'png';
    int selectedSize = 1024;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Export QR Code'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Format selection
                  const Text('Format:'),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'png', label: Text('PNG')),
                      ButtonSegment(value: 'jpg', label: Text('JPG')),
                      ButtonSegment(value: 'svg', label: Text('SVG')),
                    ],
                    selected: {selectedFormat},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() {
                        selectedFormat = selection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Size selection
                  Text('Size: $selectedSize px'),
                  Slider(
                    value: selectedSize.toDouble(),
                    min: 128,
                    max: 2048,
                    divisions: 1920 ~/ 64, // Steps of 64px
                    label: '$selectedSize px',
                    onChanged: (value) {
                      setState(() {
                        selectedSize = value.round();
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<QrCodeBloc>().add(
                  ExportQrCodeRequested(
                    format: selectedFormat,
                    size: selectedSize,
                  ),
                );
              },
              child: const Text('Export'),
            ),
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(icon),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}