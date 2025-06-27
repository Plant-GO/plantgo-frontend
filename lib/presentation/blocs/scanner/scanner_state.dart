import 'package:equatable/equatable.dart';

abstract class ScannerState extends Equatable {
  const ScannerState();

  @override
  List<Object?> get props => [];
}

class ScannerInitial extends ScannerState {}

class ScannerInitializing extends ScannerState {}

class ScannerReady extends ScannerState {}

class ScannerScanning extends ScannerState {
  final double confidence;

  const ScannerScanning({this.confidence = 0.0});

  @override
  List<Object?> get props => [confidence];
}

class ScannerSuccess extends ScannerState {
  final String plantName;
  final double confidence;
  final String? imageUrl;

  const ScannerSuccess({
    required this.plantName,
    required this.confidence,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [plantName, confidence, imageUrl];
}

class ScannerError extends ScannerState {
  final String message;

  const ScannerError({required this.message});

  @override
  List<Object?> get props => [message];
}
