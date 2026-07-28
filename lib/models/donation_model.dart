class Donation {
  final String id;
  final String restaurantName;
  final String foodName;
  final String category;
  final double quantity;
  final String imageUrl;
  final String status; // Pending, Approved, Completed, Cancelled
  final String pickupStatus; // Not Picked, In Progress, Picked
  final String? ngoName;
  final DateTime timestamp;
  final String address;

  Donation({
    required this.id,
    required this.restaurantName,
    required this.foodName,
    required this.category,
    required this.quantity,
    required this.imageUrl,
    required this.status,
    required this.pickupStatus,
    this.ngoName,
    required this.timestamp,
    required this.address,
  });

  factory Donation.fromMap(Map<String, dynamic> data, String id) {
    return Donation(
      id: id,
      restaurantName: data['restaurantName'] ?? '',
      foodName: data['foodName'] ?? '',
      category: data['category'] ?? '',
      quantity: (data['quantity'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      status: data['status'] ?? 'Pending',
      pickupStatus: data['pickupStatus'] ?? 'Not Picked',
      ngoName: data['ngoName'],
      timestamp: data['timestamp'] != null 
          ? DateTime.parse(data['timestamp'].toString()) 
          : DateTime.now(),
      address: data['pickupAddress'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'restaurantName': restaurantName,
      'foodName': foodName,
      'category': category,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'status': status,
      'pickupStatus': pickupStatus,
      'ngoName': ngoName,
      'timestamp': timestamp.toIso8601String(),
      'pickupAddress': address,
    };
  }
}
