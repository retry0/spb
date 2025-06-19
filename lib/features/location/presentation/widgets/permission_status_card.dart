import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../bloc/location_bloc.dart';

class PermissionStatusCard extends StatelessWidget {
  const PermissionStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, state) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(state),
                      color: _getStatusColor(state),
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getStatusTitle(state),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getStatusDescription(state),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (state is LocationLoaded) ...[
                  const Divider(height: 32),
                  Text(
                    'Current Location',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _buildLocationInfo(state.position),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(LocationState state) {
    if (state is LocationPermissionGranted || state is LocationLoaded) {
      return Icons.check_circle;
    } else if (state is LocationPermissionDenied) {
      return Icons.cancel;
    } else if (state is LocationPermissionError || state is LocationError) {
      return Icons.error;
    } else if (state is LocationPermissionLoading || state is LocationLoading) {
      return Icons.hourglass_top;
    } else {
      return Icons.location_on;
    }
  }

  Color _getStatusColor(LocationState state) {
    if (state is LocationPermissionGranted || state is LocationLoaded) {
      return Colors.green;
    } else if (state is LocationPermissionDenied) {
      return Colors.red;
    } else if (state is LocationPermissionError || state is LocationError) {
      return Colors.orange;
    } else if (state is LocationPermissionLoading || state is LocationLoading) {
      return Colors.blue;
    } else {
      return Colors.grey;
    }
  }

  String _getStatusTitle(LocationState state) {
    if (state is LocationPermissionGranted) {
      return 'Permission Granted';
    } else if (state is LocationPermissionDenied) {
      return 'Permission Denied';
    } else if (state is LocationPermissionError) {
      return 'Permission Error';
    } else if (state is LocationPermissionLoading) {
      return 'Requesting Permission';
    } else if (state is LocationLoaded) {
      return 'Location Available';
    } else if (state is LocationLoading) {
      return 'Getting Location';
    } else if (state is LocationError) {
      return 'Location Error';
    } else {
      return 'Location Permission';
    }
  }

  String _getStatusDescription(LocationState state) {
    if (state is LocationPermissionGranted) {
      return 'You have granted location access to this app.';
    } else if (state is LocationPermissionDenied) {
      return state.message;
    } else if (state is LocationPermissionError) {
      return state.message;
    } else if (state is LocationPermissionLoading) {
      return 'Requesting location permission...';
    } else if (state is LocationLoaded) {
      return 'Your current location has been determined.';
    } else if (state is LocationLoading) {
      return 'Getting your current location...';
    } else if (state is LocationError) {
      return state.message;
    } else {
      return 'Location permission is required for this app.';
    }
  }

  Widget _buildLocationInfo(Position position) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLocationRow('Latitude', '${position.latitude.toStringAsFixed(6)}°'),
        const SizedBox(height: 4),
        _buildLocationRow('Longitude', '${position.longitude.toStringAsFixed(6)}°'),
        const SizedBox(height: 4),
        _buildLocationRow('Altitude', '${position.altitude.toStringAsFixed(2)} m'),
        const SizedBox(height: 4),
        _buildLocationRow('Accuracy', '${position.accuracy.toStringAsFixed(2)} m'),
        const SizedBox(height: 4),
        _buildLocationRow('Speed', '${position.speed.toStringAsFixed(2)} m/s'),
        const SizedBox(height: 4),
        _buildLocationRow('Heading', '${position.heading.toStringAsFixed(2)}°'),
        const SizedBox(height: 4),
        _buildLocationRow('Timestamp', '${position.timestamp}'),
      ],
    );
  }

  Widget _buildLocationRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(value),
      ],
    );
  }
}