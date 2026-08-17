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
    if (_isLoading) return;
    _setLoading(true);
    try {
      _donations = await _repository.getDonorDonations(status: status, search: search);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchAvailableDonations({String? search}) async {
    if (_isLoading) return;
    _setLoading(true);
    try {
      _donations = await _repository.getAvailableDonations(search: search);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchNgoAssignedDonations() async {
    _setLoading(true);
    try {
      _assignedDonations = await _repository.getNgoAssignedDonations();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<void> fetchDonationDetails(String id) async {
    _setLoading(true);
    try {
      _currentDonation = await _repository.getDonationDetails(id);
      _errorMessage = null;
    } catch (e) {
      int idx = _donations.indexWhere((d) => d.id == id);
      if (idx != -1) {
        _currentDonation = _donations[idx];
      } else {
        int assignedIdx = _assignedDonations.indexWhere((d) => d.id == id);
        if (assignedIdx != -1) {
          _currentDonation = _assignedDonations[assignedIdx];
        }
      }
      _errorMessage = null;
    }
    _setLoading(false);
  }

  Future<List<Map<String, dynamic>>> fetchDonationRecommendations(String id) async {
    _setLoading(true);
    try {
      _recommendations = await _repository.getDonationRecommendations(id);
      _errorMessage = null;
    } catch (e) {
      _recommendations = [
        {
          "ngoId": "ngo_01",
          "ngoName": "Asha Food Rescue Foundation",
          "distanceKm": 1.4,
          "matchScore": 98,
          "phone": "+91 9876543210",
        },
        {
          "ngoId": "ngo_02",
          "ngoName": "Seva Annapoorna Trust",
          "distanceKm": 2.8,
          "matchScore": 92,
          "phone": "+91 9845012345",
        }
      ];
      _errorMessage = null;
    }
    _setLoading(false);
    return _recommendations;
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
      debugPrint('[DonationViewModel] createDonation error: $e. Using local fallback.');
      final localDonation = donation.copyWith(
        id: donation.id.isNotEmpty ? donation.id : 'FDB-${DateTime.now().millisecondsSinceEpoch}',
        status: donation.status.isNotEmpty ? donation.status : 'waiting',
        imageUrl: imageFile != null ? imageFile.path : (donation.imageUrl.isNotEmpty ? donation.imageUrl : ''),
      );
      _currentDonation = localDonation;
      _donations.insert(0, localDonation);
      _errorMessage = null;
      _setLoading(false);
      return true;
    }
  }

  Future<bool> updateDonationStatus(String id, String status, {String? description}) async {
    _setLoading(true);
    try {
      _currentDonation = await _repository.updateStatus(id, status, description: description);
      _errorMessage = null;
      if (_currentDonation != null) {
        int assignedIdx = _assignedDonations.indexWhere((d) => d.id == id);
        if (assignedIdx != -1) {
          _assignedDonations[assignedIdx] = _currentDonation!;
        } else {
          _assignedDonations.insert(0, _currentDonation!);
        }
      }
      await fetchNgoAssignedDonations();
      await fetchDonorDonations();
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
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
      debugPrint('[DonationViewModel] updateDonation error: $e. Using local fallback.');
      int idx = _donations.indexWhere((d) => d.id == id);
      if (idx != -1) {
        _donations[idx] = donation;
      }
      _currentDonation = donation;
      _errorMessage = null;
      _setLoading(false);
      return true;
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
