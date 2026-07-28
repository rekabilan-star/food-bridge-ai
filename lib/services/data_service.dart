import 'dart:async';
import '../models/donation_request.dart';

class DataService {
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

  final _donationController = StreamController<List<DonationRequest>>.broadcast();
  final _notificationController = StreamController<List<Map<String, dynamic>>>.broadcast();

  final List<DonationRequest> _donations = [
    DonationRequest(
      id: '882',
      restaurantName: 'Hotel Saravana Bhavan',
      foodName: 'Vegetable Stew',
      quantity: '5.0 kg',
      address: 'Anna Nagar, Chennai',
      status: 'delivered',
      expiryTime: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    DonationRequest(
      id: '881',
      restaurantName: 'A2B Sweets',
      foodName: 'Samosas',
      quantity: '2.5 kg',
      address: 'T. Nagar, Chennai',
      status: 'pending',
      expiryTime: DateTime.now().add(const Duration(hours: 3)),
    ),
  ];

  final List<Map<String, dynamic>> _notifications = [];

  Stream<List<DonationRequest>> get donationStream => _donationController.stream;
  Stream<List<Map<String, dynamic>>> get notificationStream => _notificationController.stream;
  List<DonationRequest> get currentDonations => List.unmodifiable(_donations);

  void addDonation(DonationRequest request) {
    _donations.insert(0, request);
    _donationController.add(_donations);
    _notify('New Donation', '${request.restaurantName} added ${request.foodName}', 0xFF4CAF50);
  }

  void updateDonationStatus(String id, String newStatus) {
    final index = _donations.indexWhere((d) => d.id == id);
    if (index != -1) {
      final d = _donations[index];
      _donations[index] = DonationRequest(
        id: d.id,
        restaurantName: d.restaurantName,
        foodName: d.foodName,
        quantity: d.quantity,
        address: d.address,
        status: newStatus,
        expiryTime: d.expiryTime,
      );
      _donationController.add(_donations);
      _notify('Status Update', 'Donation #$id is now $newStatus', 0xFF2196F3);
    }
  }

  void _notify(String title, String body, int color) {
    _notifications.insert(0, {
      'title': title,
      'body': body,
      'time': 'Just now',
      'color': color,
      'icon': 0xe333,
    });
    _notificationController.add(_notifications);
  }
}
