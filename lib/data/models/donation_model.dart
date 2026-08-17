class TimelineModel {
  final String status;
  final DateTime time;
  final String description;

  TimelineModel({
    required this.status,
    required this.time,
    required this.description,
  });

  factory TimelineModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime;
    try {
      parsedTime = json['time'] != null ? DateTime.parse(json['time'].toString()) : DateTime.now();
    } catch (_) {
      parsedTime = DateTime.now();
    }
    return TimelineModel(
      status: json['status'] ?? '',
      time: parsedTime,
      description: json['description'] ?? '',
    );
  }
}

class FoodItem {
  final String foodName;
  final String category;
  final int membersServed;

  FoodItem({
    required this.foodName,
    required this.category,
    required this.membersServed,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      foodName: json['foodName'] ?? '',
      category: json['category'] ?? '',
      membersServed: json['membersServed'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodName': foodName,
      'category': category,
      'membersServed': membersServed,
    };
  }
}

class QualityChecklist {
  final bool isFreshlyPrepared;
  final bool isProperlyPacked;
  final String foodType;
  final bool hasAllergens;

  QualityChecklist({
    this.isFreshlyPrepared = false,
    this.isProperlyPacked = false,
    this.foodType = 'Cooked Meal',
    this.hasAllergens = false,
  });

  factory QualityChecklist.fromJson(Map<String, dynamic> json) {
    return QualityChecklist(
      isFreshlyPrepared: json['isFreshlyPrepared'] ?? false,
      isProperlyPacked: json['isProperlyPacked'] ?? false,
      foodType: json['foodType'] ?? 'Cooked Meal',
      hasAllergens: json['hasAllergens'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    String validFoodType = foodType;
    if (validFoodType == 'Non-Vegetarian' || validFoodType == 'Non-Veg') {
      validFoodType = 'Non-Veg';
    } else if (validFoodType == 'Both') {
      validFoodType = 'Both';
    } else {
      validFoodType = 'Veg';
    }
    return {
      'isFreshlyPrepared': isFreshlyPrepared,
      'isProperlyPacked': isProperlyPacked,
      'foodType': validFoodType,
      'hasAllergens': hasAllergens,
    };
  }
}

class DeliveryDetailsModel {
  final String? photoUrl;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int? membersServed;
  final String? notes;
  final DateTime? completedAt;

  DeliveryDetailsModel({
    this.photoUrl,
    this.address,
    this.latitude,
    this.longitude,
    this.membersServed,
    this.notes,
    this.completedAt,
  });

  factory DeliveryDetailsModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedCompletedAt;
    try {
      parsedCompletedAt = json['completedAt'] != null ? DateTime.parse(json['completedAt'].toString()) : null;
    } catch (_) {
      parsedCompletedAt = null;
    }
    return DeliveryDetailsModel(
      photoUrl: json['photoUrl'],
      address: json['location']?['address'],
      latitude: json['location']?['latitude']?.toDouble(),
      longitude: json['location']?['longitude']?.toDouble(),
      membersServed: json['membersServed'],
      notes: json['notes'],
      completedAt: parsedCompletedAt,
    );
  }
}

class DonationModel {
  final String id;
  final String donorId;
  final String? donorName;
  final String? donorPhone;
  final List<FoodItem> items;
  final String foodName;
  final String category;
  final int membersServed;
  final String imageUrl;
  final DateTime preparedTime;
  final DateTime bestBeforeTime;
  final QualityChecklist checklist;
  final bool isScheduled;
  final DateTime? scheduledTimestamp;
  final String pickupAddress;
  final double latitude;
  final double longitude;
  final String? specialInstructions;
  final String status;
  final String? assignedNgoId;
  final String? assignedNgoName;
  final String? assignedNgoPhone;
  final String? volunteerId;
  final double? ngoLat;
  final double? ngoLng;
  final String? qrCode;
  final List<TimelineModel> timeline;
  final DeliveryDetailsModel? deliveryDetails;

  DonationModel({
    required this.id,
    required this.donorId,
    this.donorName,
    this.donorPhone,
    this.items = const [],
    required this.foodName,
    required this.category,
    required this.membersServed,
    required this.imageUrl,
    required this.preparedTime,
    required this.bestBeforeTime,
    QualityChecklist? checklist,
    this.isScheduled = false,
    this.scheduledTimestamp,
    required this.pickupAddress,
    required this.latitude,
    required this.longitude,
    this.specialInstructions,
    required this.status,
    this.assignedNgoId,
    this.assignedNgoName,
    this.assignedNgoPhone,
    this.volunteerId,
    this.ngoLat,
    this.ngoLng,
    this.qrCode,
    this.timeline = const [],
    this.deliveryDetails,
  }) : checklist = checklist ?? QualityChecklist();

  factory DonationModel.fromJson(Map<String, dynamic> json) {
    final donorData = json['donorId'] is Map ? json['donorId'] : null;
    final ngoData = json['assignedNgoId'] is Map ? json['assignedNgoId'] : null;

    return DonationModel(
      id: json['_id'] ?? json['id'] ?? '',
      donorId: donorData != null ? (donorData['_id'] ?? '') : (json['donorId'] ?? ''),
      donorName: donorData != null ? donorData['name'] : null,
      donorPhone: donorData != null ? donorData['phoneNumber'] : null,
      items: (json['items'] as List? ?? [])
          .map((i) => FoodItem.fromJson(i))
          .toList(),
      foodName: json['foodName'] ?? '',
      category: json['category'] ?? '',
      membersServed: json['membersServed'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      preparedTime: json['preparedTime'] != null ? DateTime.parse(json['preparedTime']) : DateTime.now(),
      bestBeforeTime: json['bestBeforeTime'] != null ? DateTime.parse(json['bestBeforeTime']) : DateTime.now(),
      checklist: QualityChecklist.fromJson(json['checklist'] ?? {}),
      isScheduled: json['isScheduled'] ?? false,
      scheduledTimestamp: json['scheduledTimestamp'] != null 
          ? DateTime.parse(json['scheduledTimestamp']) : null,
      pickupAddress: json['pickupAddress'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      specialInstructions: json['specialInstructions'],
      status: json['status'] ?? 'waiting',
      assignedNgoId: ngoData != null ? ngoData['_id'] : json['assignedNgoId'],
      assignedNgoName: ngoData != null ? ngoData['name'] : json['assignedNgoName'],
      assignedNgoPhone: ngoData != null ? ngoData['phoneNumber'] : null,
      volunteerId: json['volunteerId'],
      ngoLat: ngoData != null ? (ngoData['currentLatitude'] ?? ngoData['latitude'])?.toDouble() : null,
      ngoLng: ngoData != null ? (ngoData['currentLongitude'] ?? ngoData['longitude'])?.toDouble() : null,
      qrCode: json['qrCode'],
      timeline: (json['timeline'] as List? ?? [])
          .map((t) => TimelineModel.fromJson(t))
          .toList(),
      deliveryDetails: json['deliveryDetails'] != null
          ? DeliveryDetailsModel.fromJson(json['deliveryDetails'])
          : null,
    );
  }

  DonationModel copyWith({
    String? id,
    String? donorId,
    String? donorName,
    String? donorPhone,
    List<FoodItem>? items,
    String? foodName,
    String? category,
    int? membersServed,
    String? imageUrl,
    DateTime? preparedTime,
    DateTime? bestBeforeTime,
    QualityChecklist? checklist,
    bool? isScheduled,
    DateTime? scheduledTimestamp,
    String? pickupAddress,
    double? latitude,
    double? longitude,
    String? specialInstructions,
    String? status,
    String? assignedNgoId,
    String? assignedNgoName,
    String? assignedNgoPhone,
    double? ngoLat,
    double? ngoLng,
    String? qrCode,
    List<TimelineModel>? timeline,
    DeliveryDetailsModel? deliveryDetails,
  }) {
    return DonationModel(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      donorName: donorName ?? this.donorName,
      donorPhone: donorPhone ?? this.donorPhone,
      items: items ?? this.items,
      foodName: foodName ?? this.foodName,
      category: category ?? this.category,
      membersServed: membersServed ?? this.membersServed,
      imageUrl: imageUrl ?? this.imageUrl,
      preparedTime: preparedTime ?? this.preparedTime,
      bestBeforeTime: bestBeforeTime ?? this.bestBeforeTime,
      checklist: checklist ?? this.checklist,
      isScheduled: isScheduled ?? this.isScheduled,
      scheduledTimestamp: scheduledTimestamp ?? this.scheduledTimestamp,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      status: status ?? this.status,
      assignedNgoId: assignedNgoId ?? this.assignedNgoId,
      assignedNgoName: assignedNgoName ?? this.assignedNgoName,
      assignedNgoPhone: assignedNgoPhone ?? this.assignedNgoPhone,
      ngoLat: ngoLat ?? this.ngoLat,
      ngoLng: ngoLng ?? this.ngoLng,
      qrCode: qrCode ?? this.qrCode,
      timeline: timeline ?? this.timeline,
      deliveryDetails: deliveryDetails ?? this.deliveryDetails,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((i) => i.toJson()).toList(),
      'foodName': foodName,
      'category': category,
      'membersServed': membersServed,
      'imageUrl': imageUrl,
      'preparedTime': preparedTime.toIso8601String(),
      'bestBeforeTime': bestBeforeTime.toIso8601String(),
      'checklist': checklist.toJson(),
      'isScheduled': isScheduled,
      'scheduledTimestamp': scheduledTimestamp?.toIso8601String(),
      'pickupAddress': pickupAddress,
      'latitude': latitude,
      'longitude': longitude,
      'specialInstructions': specialInstructions,
    };
  }
}
