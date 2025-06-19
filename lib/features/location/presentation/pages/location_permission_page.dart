import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/permissions/location_permission_handler.dart';
import '../bloc/location_bloc.dart';
import '../widgets/permission_status_card.dart';

class LocationPermissionPage extends StatelessWidget {
  const LocationPermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LocationBloc(
        permissionHandler: getIt<LocationPermissionHandler>(),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Location Permissions'),
        ),
        body: BlocListener<LocationBloc, LocationState>(
          listener: (context, state) {
            if (state is LocationPermissionGranted) {
              // Navigate to home page when permission is granted
              context.go('/home');
            } else if (state is LocationPermissionDenied) {
              _showExitConfirmationDialog(context);
            }
          },
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const PermissionStatusCard(),
                  const SizedBox(height: 24),
                  _buildPermissionExplanation(),
                  const SizedBox(height: 24),
                  _buildActionButtons(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionExplanation() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Why we need location access:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildExplanationItem(
              Icons.map,
              'Show your current location on maps',
            ),
            const SizedBox(height: 8),
            _buildExplanationItem(
              Icons.navigation,
              'Provide turn-by-turn navigation',
            ),
            const SizedBox(height: 8),
            _buildExplanationItem(
              Icons.location_searching,
              'Find nearby points of interest',
            ),
            const SizedBox(height: 16),
            const Text(
              'We only access your location when you are using the app. '
              'Your location data is never shared with third parties.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        final bool isLoading = state is LocationPermissionLoading;
        final bool isGranted = state is LocationPermissionGranted;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: isLoading || isGranted
                  ? null
                  : () {
                      context.read<LocationBloc>().add(
                        LocationPermissionRequested(context: context),
                      );
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(isGranted ? 'Permission Granted' : 'Grant Permission'),
            ),
            const SizedBox(height: 16),
            if (isGranted)
              ElevatedButton(
                onPressed: () {
                  context.read<LocationBloc>().add(
                    const LocationCurrentPositionRequested(),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
                child: const Text('Get Current Location'),
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _showExitConfirmationDialog(context),
              child: const Text('Exit App'),
            ),
          ],
        );
      },
    );
  }

  void _showExitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit Application?'),
          content: const Text(
            'This app requires location permissions to function properly. '
            'Without these permissions, the app cannot continue.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Try Again'),
              onPressed: () {
                Navigator.of(context).pop();
                // Request permission again
                context.read<LocationBloc>().add(
                  LocationPermissionRequested(context: context),
                );
              },
            ),
            TextButton(
              child: const Text('Exit App'),
              onPressed: () => exit(0),
            ),
          ],
        );
      },
    );
  }
}