class DonationRequest {
  final String id;
  final String restaurantName;
  final String foodName;
  final String quantity;
  final String address;
  final String status; // 'pending', 'accepted_by_ngo', 'assigned_to_volunteer', 'picked_up', 'delivered'
  final DateTime expiryTime;

  DonationRequest({
    required this.id,
    required this.restaurantName,
    required this.foodName,
    required this.quantity,
    required this.address,
    required this.status,
    required this.expiryTime,
  });
}
