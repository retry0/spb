import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/di/injection.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/qr_code_bloc.dart';
import '../widgets/qr_code_controls.dart';
import '../widgets/qr_code_preview.dart';
import '../widgets/saved_qr_codes_sidebar.dart';
import '../widgets/qr_code_action_buttons.dart';
import '../widgets/offline_indicator.dart';

class QrCodeGeneratorPage extends StatefulWidget {
  const QrCodeGeneratorPage({super.key});

  @override
  State<QrCodeGeneratorPage> createState() => _QrCodeGeneratorPageState();
}

class _QrCodeGeneratorPageState extends State<QrCodeGeneratorPage> {
  bool _showSidebar = false;
  bool _isOffline = false;
  
  @override
  void initState() {
    super.initState();
    // Check network connectivity
    _checkConnectivity();
  }
  
  Future<void> _checkConnectivity() async {
    // In a real app, implement connectivity check
    setState(() {
      _isOffline = false; // For demo purposes
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<QrCodeBloc>()
        ..add(const LoadSavedQrCodesRequested()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('QR Code Generator'),
          actions: [
            IconButton(
              icon: Icon(_showSidebar ? Icons.close : Icons.history),
              onPressed: () {
                setState(() {
                  _showSidebar = !_showSidebar;
                });
              },
              tooltip: _showSidebar ? 'Close Saved Codes' : 'Show Saved Codes',
            ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Offline indicator
                if (_isOffline) const OfflineIndicator(),
                
                // Main content
                Expanded(
                  child: _buildMainContent(),
                ),
              ],
            ),
            
            // Saved QR codes sidebar (conditionally shown)
            if (_showSidebar)
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: MediaQuery.of(context).size.width * 0.75,
                child: const SavedQrCodesSidebar(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return BlocConsumer<QrCodeBloc, QrCodeState>(
      listener: (context, state) {
        if (state is QrCodeGenerationFailure) {
          _showErrorSnackBar(context, state.message);
        } else if (state is QrCodeSaveFailure) {
          _showErrorSnackBar(context, state.message);
        } else if (state is QrCodeExportFailure) {
          _showErrorSnackBar(context, state.message);
        } else if (state is QrCodeShareFailure) {
          _showErrorSnackBar(context, state.message);
        } else if (state is QrCodeExported) {
          _showSuccessSnackBar(context, 'QR code exported successfully to: ${state.filePath}');
        } else if (state is QrCodeShared) {
          _showSuccessSnackBar(context, 'QR code shared successfully');
        } else if (state is QrCodeSaved) {
          _showSuccessSnackBar(context, 'QR code saved successfully');
        }
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // QR Code Controls
              const QrCodeControls(),
              
              const SizedBox(height: 24),
              
              // QR Code Preview
              const QrCodePreview(),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              const QrCodeActionButtons(),
            ],
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}