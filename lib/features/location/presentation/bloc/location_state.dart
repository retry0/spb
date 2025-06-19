part of 'location_bloc.dart';

abstract class LocationState extends Equatable {
  const LocationState();
  
  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {
  const LocationInitial();
}

class LocationPermissionLoading extends LocationState {
  const LocationPermissionLoading();
}

class LocationPermissionGranted extends LocationState {
  const LocationPermissionGranted();
}

class LocationPermissionDenied extends LocationState {
  final String message;
  
  const LocationPermissionDenied(this.message);
  
  @override
  List<Object?> get props => [message];
}

class LocationPermissionError extends LocationState {
  final String message;
  
  const LocationPermissionError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class LocationLoading extends LocationState {
  const LocationLoading();
}

class LocationLoaded extends LocationState {
  final Position position;
  
  const LocationLoaded(this.position);
  
  @override
  List<Object?> get props => [position];
}

class LocationError extends LocationState {
  final String message;
  
  const LocationError(this.message);
  
  @override
  List<Object?> get props => [message];
}