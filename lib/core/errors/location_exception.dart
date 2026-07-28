class LocationException implements Exception {
  final String message;
  final String? developerMessage;
  final LocationErrorType type;

  LocationException({
    required this.message,
    this.developerMessage,
    required this.type,
  });

  @override
  String toString() => 'LocationException: $message ($type)';
}

enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  geocodingFailed,
  unknown,
  noInternet,
  noSatellite,
}
