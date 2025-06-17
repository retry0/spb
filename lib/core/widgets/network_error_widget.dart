import 'package:flutter/material.dart';
import '../config/network_troubleshooter.dart';
import '../config/environment_config.dart';
import '../config/android_emulator_config.dart';
import '../utils/logger.dart';

/// Widget to display network error information and troubleshooting options
class NetworkErrorWidget extends StatefulWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;

  const NetworkErrorWidget({
    super.key,
    this.errorMessage,
    this.onRetry,
  });

  @override
  State<NetworkErrorWidget> createState() => _NetworkErrorWidgetState();
}

class _NetworkErrorWidgetState extends State<NetworkErrorWidget> {
  bool _isRunningDiagnostics = false;
  NetworkDiagnostics? _diagnostics;
  bool _showDetailedReport = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: 64,
                color: Colors.red[700],
              ),
              const SizedBox(height: 24),
              Text(
                'Network Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.errorMessage ?? 'No internet connection. Please check your network settings.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 32),
              
              // Quick info about current configuration
              _buildConfigurationInfo(),
              
              const SizedBox(height: 24),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: widget.onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isRunningDiagnostics ? null : _runDiagnostics,
                    icon: _isRunningDiagnostics 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bug_report),
                    label: const Text('Diagnose'),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Diagnostics results
              if (_diagnostics != null) _buildDiagnosticsResults(),
              
              // Quick tips
              _buildQuickTips(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigurationInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Environment', EnvironmentConfig.environmentName),
            _buildInfoRow('Base URL', EnvironmentConfig.baseUrl),
            if (AndroidEmulatorConfig.isAndroidEmulator) ...[
              _buildInfoRow('Platform', 'Android Emulator'),
              _buildInfoRow('Original URL', EnvironmentConfig.rawBaseUrl),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsResults() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Diagnostics Results',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showDetailedReport = !_showDetailedReport;
                    });
                  },
                  child: Text(_showDetailedReport ? 'Hide Details' : 'Show Details'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Quick status indicators
            _buildStatusIndicator(
              'Network Connection',
              _diagnostics!.connectivity.isConnected,
              _diagnostics!.connectivity.details,
            ),
            _buildStatusIndicator(
              'Internet Access',
              _diagnostics!.internetAccess.hasAccess,
              _diagnostics!.internetAccess.details,
            ),
            _buildStatusIndicator(
              'Backend Server',
              _diagnostics!.backendAccess.isAccessible,
              _diagnostics!.backendAccess.details,
            ),
            
            // Detailed report
            if (_showDetailedReport) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  NetworkTroubleshooter.generateTroubleshootingReport(_diagnostics!),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, bool isOk, String details) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isOk ? Icons.check_circle : Icons.error,
            color: isOk ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  details,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickTips() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Tips',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (AndroidEmulatorConfig.isAndroidEmulator) ...[
              _buildTip('For Android emulator, ensure your backend server is running on your host machine'),
              _buildTip('Use http://10.0.2.2:YOUR_PORT/api instead of localhost'),
              _buildTip('Bind your server to 0.0.0.0, not just localhost'),
            ] else ...[
              _buildTip('Check your WiFi or mobile data connection'),
              _buildTip('Ensure your backend server is running and accessible'),
              _buildTip('Verify the API endpoint URL is correct'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(tip, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isRunningDiagnostics = true;
    });

    try {
      final diagnostics = await NetworkTroubleshooter.diagnoseNetwork();
      setState(() {
        _diagnostics = diagnostics;
      });

      // Log the report for debugging
      final report = NetworkTroubleshooter.generateTroubleshootingReport(diagnostics);
      AppLogger.info('Network Diagnostics Report:\n$report');

    } catch (e) {
      AppLogger.error('Failed to run network diagnostics: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to run diagnostics: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRunningDiagnostics = false;
      });
    }
  }
}