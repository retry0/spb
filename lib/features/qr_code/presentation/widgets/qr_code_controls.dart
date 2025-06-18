import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/qr_code_bloc.dart';

class QrCodeControls extends StatefulWidget {
  const QrCodeControls({super.key});

  @override
  State<QrCodeControls> createState() => _QrCodeControlsState();
}

class _QrCodeControlsState extends State<QrCodeControls> {
  final _formKey = GlobalKey<FormState>();

  // Default values
  String? _driver;
  String? _kdVendor;
  int _size = 300;
  String _errorCorrectionLevel = 'M';
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    // Get user info from auth state
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      _driver = authState.user.userName;
      _kdVendor = authState.user.Id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'QR Code Settings',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Driver field
              TextFormField(
                initialValue: _driver,
                decoration: const InputDecoration(
                  labelText: 'Driver',
                  hintText: 'Enter driver information',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Driver information is required';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _driver = value;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Vendor field
              TextFormField(
                initialValue: _kdVendor,
                decoration: const InputDecoration(
                  labelText: 'Vendor ID',
                  hintText: 'Enter vendor ID',
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vendor ID is required';
                  }
                  return null;
                },
                onChanged: (value) {
                  setState(() {
                    _kdVendor = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Size slider
              Row(
                children: [
                  const Icon(Icons.photo_size_select_large),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Size: $_size px',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Slider(
                          value: _size.toDouble(),
                          min: 128,
                          max: 1024,
                          divisions: 896 ~/ 32, // Steps of 32px
                          label: '$_size px',
                          onChanged: (value) {
                            setState(() {
                              _size = value.round();
                            });

                            // Update QR code size if already generated
                            final state = context.read<QrCodeBloc>().state;
                            if (state is QrCodeGenerated) {
                              context.read<QrCodeBloc>().add(
                                QrCodeSizeChanged(_size),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Error correction level
              Row(
                children: [
                  const Icon(Icons.security),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Error Correction: $_errorCorrectionLevel',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'L', label: Text('L')),
                            ButtonSegment(value: 'M', label: Text('M')),
                            ButtonSegment(value: 'Q', label: Text('Q')),
                            ButtonSegment(value: 'H', label: Text('H')),
                          ],
                          selected: {_errorCorrectionLevel},
                          onSelectionChanged: (Set<String> selection) {
                            setState(() {
                              _errorCorrectionLevel = selection.first;
                            });

                            // Update QR code error correction if already generated
                            final state = context.read<QrCodeBloc>().state;
                            if (state is QrCodeGenerated) {
                              context.read<QrCodeBloc>().add(
                                QrCodeErrorCorrectionChanged(
                                  _errorCorrectionLevel,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Theme switch
              Row(
                children: [
                  const Icon(Icons.color_lens),
                  const SizedBox(width: 8),
                  Text(
                    'Dark Mode:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        _isDarkMode = value;
                      });

                      // Update QR code theme if already generated
                      final state = context.read<QrCodeBloc>().state;
                      if (state is QrCodeGenerated) {
                        context.read<QrCodeBloc>().add(
                          QrCodeThemeChanged(
                            foregroundColor:
                                _isDarkMode ? '#FFFFFF' : '#000000',
                            backgroundColor:
                                _isDarkMode ? '#000000' : '#FFFFFF',
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Generate button
              SizedBox(
                width: double.infinity,
                child: BlocBuilder<QrCodeBloc, QrCodeState>(
                  builder: (context, state) {
                    final isGenerating = state is QrCodeGenerating;

                    return ElevatedButton(
                      onPressed: isGenerating ? null : _generateQrCode,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child:
                          isGenerating
                              ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : const Text('Generate QR Code'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _generateQrCode() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<QrCodeBloc>().add(
        GenerateQrCodeRequested(
          driver: _driver!,
          kdVendor: _kdVendor!,
          size: _size,
          errorCorrectionLevel: _errorCorrectionLevel,
          foregroundColor: _isDarkMode ? '#FFFFFF' : '#000000',
          backgroundColor: _isDarkMode ? '#000000' : '#FFFFFF',
        ),
      );
    }
  }
}
