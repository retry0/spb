import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/permissions/location_permission_handler.dart';
import '../../../../core/utils/logger.dart';

part 'location_event.dart';
part 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final LocationPermissionHandler _permissionHandler;
  StreamSubscription? _permissionStatusSubscription;
  
  LocationBloc({
    required LocationPermissionHandler permissionHandler,
  }) : _permissionHandler = permissionHandler,
       super(const LocationInitial()) {
    on<LocationPermissionRequested>(_onLocationPermissionRequested);
    on<LocationPermissionStatusChanged>(_onLocationPermissionStatusChanged);
    on<LocationCurrentPositionRequested>(_onLocationCurrentPositionRequested);
    
    // Listen to permission status changes
    _permissionStatusSubscription = _permissionHandler.permissionStatusStream.listen(
      (isGranted) {
        add(LocationPermissionStatusChanged(isGranted: isGranted));
      },
    );
  }
  
  Future<void> _onLocationPermissionRequested(
    LocationPermissionRequested event,
    Emitter<LocationState> emit,
  ) async {
    emit(const LocationPermissionLoading());
    
    try {
      final isGranted = await _permissionHandler.requestPermission(event.context);
      
      if (isGranted) {
        emit(const LocationPermissionGranted());
      } else {
        emit(const LocationPermissionDenied('Location permission is required'));
      }
    } catch (e) {
      AppLogger.error('Failed to request location permission', e);
      emit(LocationPermissionError('Failed to request permission: $e'));
    }
  }
  
  void _onLocationPermissionStatusChanged(
    LocationPermissionStatusChanged event,
    Emitter<LocationState> emit,
  ) {
    if (event.isGranted) {
      emit(const LocationPermissionGranted());
    } else {
      emit(const LocationPermissionDenied('Location permission is required'));
    }
  }
  
  Future<void> _onLocationCurrentPositionRequested(
    LocationCurrentPositionRequested event,
    Emitter<LocationState> emit,
  ) async {
    // Check if permission is granted first
    if (!_permissionHandler.isPermissionGranted) {
      emit(const LocationPermissionDenied('Location permission is required'));
      return;
    }
    
    emit(const LocationLoading());
    
    try {
      final position = await _permissionHandler.getCurrentPosition(
        accuracy: event.accuracy,
        timeout: event.timeout,
      );
      
      if (position != null) {
        emit(LocationLoaded(position));
      } else {
        emit(const LocationError('Failed to get current position'));
      }
    } catch (e) {
      AppLogger.error('Failed to get current position', e);
      emit(LocationError('Failed to get current position: $e'));
    }
  }
  
  @override
  Future<void> close() {
    _permissionStatusSubscription?.cancel();
    return super.close();
  }
}