class LocationModel {
  final double latitude;
  final double longitude;
  final String fullAddress;
  final String? street;
  final String? locality;
  final String? subLocality;
  final String? city;
  final String? district;
  final String? state;
  final String? postalCode;
  final String? country;
  final DateTime timestamp;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.fullAddress,
    this.street,
    this.locality,
    this.subLocality,
    this.city,
    this.district,
    this.state,
    this.postalCode,
    this.country,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'fullAddress': fullAddress,
      'street': street,
      'locality': locality,
      'subLocality': subLocality,
      'city': city,
      'district': district,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: json['latitude'],
      longitude: json['longitude'],
      fullAddress: json['fullAddress'],
      street: json['street'],
      locality: json['locality'],
      subLocality: json['subLocality'],
      city: json['city'],
      district: json['district'],
      state: json['state'],
      postalCode: json['postalCode'],
      country: json['country'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
