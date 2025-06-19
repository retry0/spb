part of 'location_bloc.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class LocationPermissionRequested extends LocationEvent {
  final dynamic context;
  
  const LocationPermissionRequested({required this.context});
  
  @override
  List<Object?> get props => [context];
}

class LocationPermissionStatusChanged extends LocationEvent {
  final bool isGranted;
  
  const LocationPermissionStatusChanged({required this.isGranted});
  
  @override
  List<Object?> get props => [isGranted];
}

class LocationCurrentPositionRequested extends LocationEvent {
  final LocationAccuracy accuracy;
  final Duration timeout;
  
  const LocationCurrentPositionRequested({
    this.accuracy = LocationAccuracy.high,
    this.timeout = const Duration(seconds: 30),
  });
  
  @override
  List<Object?> get props => [accuracy, timeout];
}