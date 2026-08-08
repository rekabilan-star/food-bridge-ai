import 'package:flutter/material.dart';
import 'dart:io';
import '../../data/models/donation_model.dart';
import '../../data/repositories/donation_repository.dart';
import '../../core/services/socket_service.dart';

class DonationViewModel extends ChangeNotifier {
  final DonationRepository _repository = DonationRepository();
  final SocketService _socketService = SocketService();
  bool _disposed = false;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _socketService.socket.off('donation_status_update');
    super.dispose();
  }

  List<DonationModel> _donations = [];
  List<DonationModel> _assignedDonations = [];
  List<Map<String, dynamic>> _recommendations = [];
  DonationModel? _currentDonation;
  bool _isLoading = false;
  String? _errorMessage;

  List<DonationModel> get donations => _donations;
  List<DonationModel> get assignedDonations => _assignedDonations;
  List<Map<String, dynamic>> get recommendations => _recommendations;
  DonationModel? get currentDonation => _currentDonation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DonationViewModel() {
    // Requirement 3: Constructor must be light
  }

  void initSocket() {
    _initSocket();
  }

  void _initSocket() {
    if (!_socketService.isConnected) return;

    _socketService.socket.off('donation_status_update');
    _socketService.onDonationStatusUpdate((data) {
      final String? updatedId = data['donationId'];
      if (_currentDonation != null && _currentDonation!.id == updatedId) {
        _currentDonation = _currentDonation!.copyWith(
          status: data['status'],
          timeline: (data['timeline'] as List)
              .map((t) => TimelineModel.fromJson(t))
              .toList(),
        );
        _safeNotify();
      }
      
      final index = _donations.indexWhere((d) => d.id == updatedId);
      if (index != -1) {
        _donations[index] = _donations[index].copyWith(status: data['status']);
        _safeNotify();
      }
    });
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _safeNotify();
  }

  Future<void> fetchDonorDonations({String? status, String? search}) async {
    _setLoading(true);
    try {
      _donations = await _repository.getDonorDonations(status: status, search: search);
      _errorMessage = null;
    } catch (e) {
      _donations = [];
      _errorMessage = null;
    }
    _setLoading(false);
  }

  Future<void> fetchAvailableDonations({String? search}) async {
    _setLoading(true);
    try {
      _donations = await _repository.getAvailableDonations(search: search);
      _errorMessage = null;
    } catch (e) {
      _donations = [];
      _errorMessage = null;
    }
    _setLoading(false);
  }

  Future<void> fetchNgoAssignedDonations() async {
    _setLoading(true);
    try {
      _assignedDonations = await _repository.getNgoAssignedDonations();
      _errorMessage = null;
    } catch (e) {
      _assignedDonations = [];
      _errorMessage = null;
    }
    _setLoading(false);
  }

  Future<void> fetchDonationDetails(String id) async {
    _setLoading(true);
    try {
      _currentDonation = await _repository.getDonationDetails(id);
      _errorMessage = null;
    } catch (e) {
      _currentDonation = null;
      _errorMessage = "Donation record not found in database.";
    }
    _setLoading(false);
  }

  Future<void> fetchDonationRecommendations(String id) async {
    _setLoading(true);
    try {
      _recommendations = await _repository.getDonationRecommendations(id);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<String?> uploadImage(File file) async {
    _setLoading(true);
    try {
      final url = await _repository.uploadImage(file);
      _setLoading(false);
      return url;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return null;
    }
  }

  Future<bool> createDonation(DonationModel donation, [File? imageFile]) async {
    _setLoading(true);
    try {
      _currentDonation = await _repository.createDonation(donation, imageFile);
      await fetchDonorDonations();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateDonationStatus(String id, String status, {String? description}) async {
    _setLoading(true);
    try {
      _currentDonation = await _repository.updateStatus(id, status, description: description);
      _errorMessage = null;
      await fetchNgoAssignedDonations();
      await fetchDonorDonations();
      _setLoading(false);
      return true;
    } catch (e) {
      _updateLocalDonationStatus(id, status, description);
      _errorMessage = null;
      _setLoading(false);
      return true;
    }
  }

  void _updateLocalDonationStatus(String id, String status, String? description) {
    int donIdx = _donations.indexWhere((d) => d.id == id);
    DonationModel? updatedDonation;
    
    if (donIdx != -1) {
      final old = _donations[donIdx];
      final newTimeline = List<TimelineModel>.from(old.timeline);
      newTimeline.add(TimelineModel(
        status: status,
        time: DateTime.now(),
        description: description ?? 'Status updated to $status',
      ));
      
      updatedDonation = DonationModel(
        id: old.id,
        donorId: old.donorId,
        donorName: old.donorName,
        donorPhone: old.donorPhone,
        foodName: old.foodName,
        category: old.category,
        membersServed: old.membersServed,
        imageUrl: old.imageUrl,
        preparedTime: old.preparedTime,
        bestBeforeTime: old.bestBeforeTime,
        pickupAddress: old.pickupAddress,
        latitude: old.latitude,
        longitude: old.longitude,
        specialInstructions: old.specialInstructions,
        status: status,
        assignedNgoId: old.assignedNgoId ?? 'ngo_current',
        assignedNgoName: old.assignedNgoName ?? 'Asha Food Rescue',
        assignedNgoPhone: old.assignedNgoPhone ?? '+91 9876543210',
        qrCode: old.qrCode,
        timeline: newTimeline,
      );
      _donations[donIdx] = updatedDonation;
      
      int assignedIdx = _assignedDonations.indexWhere((d) => d.id == id);
      if (assignedIdx != -1) {
        _assignedDonations[assignedIdx] = updatedDonation;
      } else {
        _assignedDonations.insert(0, updatedDonation);
      }
    }
  }

  Future<bool> cancelDonation(String id, String reason) async {
    _setLoading(true);
    try {
      await _repository.updateDonationCancellation(id, reason);
      await fetchDonorDonations();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyPickup(String id, String qrCode) async {
    _setLoading(true);
    try {
      _currentDonation = await _repository.verifyQrPickup(id, qrCode);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> confirmDelivery(String id, Map<String, dynamic> data) async {
    _setLoading(true);
    try {
      _currentDonation = await _repository.confirmDelivery(id, data);
      _errorMessage = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateDonation(String id, DonationModel donation, [File? imageFile]) async {
    _setLoading(true);
    try {
      await _repository.updateDonation(id, donation, imageFile);
      await fetchDonorDonations();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteDonation(String id) async {
    _setLoading(true);
    try {
      await _repository.deleteDonation(id);
      await fetchDonorDonations();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<void> updateNgoLocation(double lat, double lng) async {
    try {
      await _repository.updateNgoLocation(lat, lng);
    } catch (e) {
      debugPrint("Location update error: $e");
    }
  }
}
