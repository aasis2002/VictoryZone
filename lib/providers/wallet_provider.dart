import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet_request_model.dart';
import '../models/app_config_model.dart';
import '../services/firestore_service.dart';

class WalletProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  AppConfigModel? _config;
  bool _isLoading = false;

  AppConfigModel? get config => _config;
  bool get isLoading => _isLoading;

  Future<void> fetchConfig() async {
    _config = await _firestoreService.getAppConfig();
    notifyListeners();
  }

  Future<void> requestWallet(String userId, double amount, String refId, {String? screenshotUrl}) async {
    _isLoading = true;
    notifyListeners();
    try {
      WalletRequestModel request = WalletRequestModel(
        requestId: const Uuid().v4(),
        userId: userId,
        amount: amount,
        esewaRefId: refId,
        screenshotUrl: screenshotUrl,
        status: 'pending',
        timestamp: Timestamp.now(),
      );
      await _firestoreService.submitWalletRequest(request);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> requestWithdrawal(String userId, double amount, String esewaId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _firestoreService.submitWithdrawalRequest(
        userId: userId,
        amount: amount,
        esewaId: esewaId,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
