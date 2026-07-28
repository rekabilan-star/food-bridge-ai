import 'package:flutter/material.dart';
import 'dart:io';
import '../../data/models/donation_model.dart';
import '../../data/repositories/donation_repository.dart';

class DonationViewModel extends ChangeNotifier {
  final DonationRepository _repository = DonationRepository();
  
  List<DonationModel> _donations = [];
  List<DonationModel> _assignedDonations = [];
  DonationModel? _currentDonation;
  bool _isLoading = false;
  String? _errorMessage;

  List<DonationModel> get donations => _donations;
  List<DonationModel> get assignedDonations => _assignedDonations;
  DonationModel? get currentDonation => _currentDonation;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchDonorDonations({String? status, String? search}) async {
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
      _errorMessage = e.toString();
    }
    _setLoading(false);
  }

  Future<bool> createDonation(DonationModel donation, [File? imageFile]) async {
    _setLoading(true);
    try {
      await _repository.createDonation(donation, imageFile);
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

  Future<void> updateNgoLocation(double lat, double lng) async {
    try {
      await _repository.updateNgoLocation(lat, lng);
    } catch (e) {
      debugPrint("Location update error: $e");
    }
  }
}
