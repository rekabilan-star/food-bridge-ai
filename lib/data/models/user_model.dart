enum UserRole { donor, ngo, admin, volunteer }

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String phoneNumber;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? profileImage;
  final DateTime? lastLogin;
  
  // NGO Specific Fields
  final String? ngoRegistrationNumber;
  final String? ngoCertificateUrl;
  final String? ngoIdProofUrl;
  final String? status; // pending, approved, rejected
  
  // New Features
  final String? availabilityStatus; // Available, Busy, Offline
  final double averageRating;
  final int totalRatings;
  final List<String> acceptedCategories;
  final int maxDailyMeals;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.phoneNumber,
    this.address,
    this.latitude,
    this.longitude,
    this.profileImage,
    this.lastLogin,
    this.ngoRegistrationNumber,
    this.ngoCertificateUrl,
    this.ngoIdProofUrl,
    this.status,
    this.availabilityStatus,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.acceptedCategories = const [],
    this.maxDailyMeals = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? 'Unknown User',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == json['role'],
        orElse: () => UserRole.donor,
      ),
      phoneNumber: json['phoneNumber'] ?? '',
      address: json['address'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      profileImage: json['profileImage'],
      lastLogin: json['lastLogin'] != null ? DateTime.parse(json['lastLogin']) : null,
      ngoRegistrationNumber: json['ngoRegistrationNumber'],
      ngoCertificateUrl: json['ngoCertificateUrl'],
      ngoIdProofUrl: json['ngoIdProofUrl'],
      status: json['status'],
      availabilityStatus: json['availabilityStatus'],
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      acceptedCategories: (json['acceptedCategories'] as List? ?? []).map((e) => e.toString()).toList(),
      maxDailyMeals: json['maxDailyMeals'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'phoneNumber': phoneNumber,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'profileImage': profileImage,
      'lastLogin': lastLogin?.toIso8601String(),
      'ngoRegistrationNumber': ngoRegistrationNumber,
      'ngoCertificateUrl': ngoCertificateUrl,
      'ngoIdProofUrl': ngoIdProofUrl,
      'status': status,
      'availabilityStatus': availabilityStatus,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'acceptedCategories': acceptedCategories,
      'maxDailyMeals': maxDailyMeals,
    };
  }
}
