import 'package:flutter/material.dart';
import 'dart:io';
import '../../data/models/donation_model.dart';
import '../../data/repositories/donation_repository.dart';
import '../../core/services/socket_service.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/utils/ui_utils.dart';
import 'auth_viewmodel.dart';

class DonationViewModel extends ChangeNotifier {
  final DonationRepository _repository = DonationRepository();
  final SocketService _socketService = SocketService();
  bool _disposed = false;
  String? _lastNotifiedEventKey;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _socketService.socket.off('donation_status_update');
    _socketService.socket.off('new_donation');
    _socketService.socket.off('donation_claimed');
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
    AuthViewModel.registerLogoutHook(clear);
  }

  void clear() {
    _donations = [];
    _assignedDonations = [];
    _recommendations = [];
    _currentDonation = null;
    _isLoading = false;
    _errorMessage = null;
    _safeNotify();
  }

  void initSocket() {
    _initSocket();
  }

  void _initSocket() {
    if (!_socketService.isConnected) return;

    _socketService.socket.off('donation_status_update');
    _socketService.onDonationStatusUpdate((data) {
      final String? updatedId = data['donationId'] ?? data['donation']?['_id'] ?? data['donation']?['id'];
      final String? newStatus = data['status'] ?? data['donation']?['status'];
      final List timelineList = (data['timeline'] as List? ?? data['donation']?['timeline'] as List? ?? []);
      final parsedTimeline = timelineList.map((t) => TimelineModel.fromJson(t)).toList();

      if (_currentDonation != null && _currentDonation!.id == updatedId && newStatus != null) {
        _currentDonation = _currentDonation!.copyWith(
          status: newStatus,
          timeline: parsedTimeline.isNotEmpty ? parsedTimeline : _currentDonation!.timeline,
        );
      }
      
      final index = _donations.indexWhere((d) => d.id == updatedId);
      if (index != -1 && newStatus != null) {
        _donations[index] = _donations[index].copyWith(
          status: newStatus,
          timeline: parsedTimeline.isNotEmpty ? parsedTimeline : _donations[index].timeline,
        );
      }

      final assignedIdx = _assignedDonations.indexWhere((d) => d.id == updatedId);
      if (assignedIdx != -1 && newStatus != null) {
        _assignedDonations[assignedIdx] = _assignedDonations[assignedIdx].copyWith(
          status: newStatus,
          timeline: parsedTimeline.isNotEmpty ? parsedTimeline : _assignedDonations[assignedIdx].timeline,
        );
      }

      _safeNotify();

      // Non-blocking local heads-up notification display with duplicate event protection
      try {
        if (updatedId != null && newStatus != null) {
          final String timeStampKey = parsedTimeline.isNotEmpty
              ? parsedTimeline.last.time.millisecondsSinceEpoch.toString()
              : DateTime.now().minute.toString();
          final String currentEventKey = "${updatedId}_${newStatus}_$timeStampKey";

          if (_lastNotifiedEventKey != currentEventKey) {
            _lastNotifiedEventKey = currentEventKey;
            PushNotificationService.showNotification(
              title: "Donation Status Updated",
              body: "Your donation is now ${StatusUtils.formatStatusLabel(newStatus)}",
            );
          }
        }
      } catch (e) {
        debugPrint('[DonationViewModel] Non-blocking local notification error: $e');
      }
    });

    // Real-time listener for incoming available donations for NGOs within 20 KM
    _socketService.onNewDonation((data) {
      try {
        final newDonation = DonationModel.fromJson(data);
        if (newDonation.id.isEmpty) return;

        final alreadyExists = _donations.any((d) => d.id == newDonation.id);
        if (!alreadyExists) {
          _donations.insert(0, newDonation);
          _safeNotify();

          PushNotificationService.showNotification(
            title: "New Donation Available 🥗",
            body: "${newDonation.foodName} is now available within your area.",
          );
        }
      } catch (e) {
        debugPrint('[DonationViewModel] new_donation socket parse error: $e');
      }
    });

    // Real-time listener for donation_claimed: evicts claimed donations from available list
    _socketService.onDonationClaimed((data) {
      try {
        final String? claimedId = data['donationId']?.toString();
        if (claimedId == null || claimedId.isEmpty) return;

        bool changed = false;
        final initialLength = _donations.length;
        _donations.removeWhere((d) => d.id == claimedId);
        if (_donations.length != initialLength) {
          changed = true;
        }

        if (_currentDonation != null && _currentDonation!.id == claimedId && _currentDonation!.status == 'waiting') {
          _currentDonation = _currentDonation!.copyWith(status: 'accepted');
          changed = true;
        }

        if (changed) {
          _safeNotify();
        }
      } catch (e) {
        debugPrint('[DonationViewModel] donation_claimed socket parse error: $e');
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
      debugPrint('[DonationViewModel] fetchDonationRecommendations error: $e');
      _recommendations = [];
      _errorMessage = e.toString();
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
      _errorMessage = null;
      await fetchDonorDonations();
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('[DonationViewModel] createDonation failed: $e');
      _errorMessage = e.toString().replaceAll("Exception:", "").trim();
      _setLoading(false);
      return false;
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
      await fetchNgoAssignedDonations();
      await fetchDonorDonations();
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
      await fetchNgoAssignedDonations();
      await fetchDonorDonations();
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

  Future<Map<String, dynamic>> verifyRescueQr(String qrCode) async {
    try {
      return await _repository.verifyRescueQr(qrCode);
    } catch (e) {
      debugPrint('[DonationViewModel] verifyRescueQr error: $e');
      rethrow;
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
