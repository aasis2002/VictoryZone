import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../core/constants.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _userModel;
  bool _isLoading = false;
  StreamSubscription? _userSubscription;

  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _authService.userStream.listen((user) {
      if (user != null) {
        _startUserListener(user.uid);
      } else {
        _stopUserListener();
      }
    });
  }

  void _startUserListener(String uid) {
    _userSubscription?.cancel();
    _userSubscription = FirebaseFirestore.instance
        .collection(AppConstants.usersColl)
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        _userModel = UserModel.fromMap(doc.data() as Map<String, dynamic>);
        notifyListeners();
      }
    });
  }

  void _stopUserListener() {
    _userSubscription?.cancel();
    _userModel = null;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.login(email, password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.signInWithGoogle();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String name, String email, String password, String phoneNumber) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.register(name, email, password, phoneNumber);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.resetPassword(email);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.logout();
  }

  Future<void> updateProfile({
    required String name,
    required String phoneNumber,
    String? pubgId,
    String? freefireId,
    String? photoUrl,
  }) async {
    if (_userModel == null) return;
    await _authService.updateProfile(
      uid: _userModel!.uid,
      name: name,
      phoneNumber: phoneNumber,
      pubgId: pubgId,
      freefireId: freefireId,
      photoUrl: photoUrl,
    );
  }

  Future<void> reportUser(String reportedUid, String reason) async {
    if (_userModel == null) return;
    await _authService.reportUser(reportedUid, _userModel!.uid, reason);
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }
}
