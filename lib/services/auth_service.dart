import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../core/constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get userStream => _auth.authStateChanges();

  Future<UserModel?> register(String name, String email, String password, String phoneNumber) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        UserModel userModel = UserModel(
          uid: user.uid,
          name: name,
          email: email,
          phoneNumber: phoneNumber,
          walletBalance: 0,
          role: 'user',
        );
        await _db.collection(AppConstants.usersColl).doc(user.uid).set(userModel.toMap());
        return userModel;
      }
    } catch (e) {
      debugPrint('Registration Error: $e');
      rethrow;
    }
    return null;
  }

  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      debugPrint('Login Error: $e');
      rethrow;
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        // Check if user exists in Firestore
        DocumentSnapshot doc = await _db.collection(AppConstants.usersColl).doc(user.uid).get();
        if (!doc.exists) {
          UserModel userModel = UserModel(
            uid: user.uid,
            name: user.displayName ?? 'Player',
            email: user.email ?? '',
            photoUrl: user.photoURL,
            walletBalance: 0,
            role: 'user',
          );
          await _db.collection(AppConstants.usersColl).doc(user.uid).set(userModel.toMap());
        }
      }
      return user;
    } catch (e) {
      debugPrint('Google Sign In Error: $e');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Reset Password Error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<UserModel?> getUserData(String uid) async {
    DocumentSnapshot doc = await _db.collection(AppConstants.usersColl).doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> updateProfile({
    required String uid,
    required String name,
    required String phoneNumber,
    String? pubgId,
    String? freefireId,
    String? photoUrl,
  }) async {
    await _db.collection(AppConstants.usersColl).doc(uid).update({
      'name': name,
      'phoneNumber': phoneNumber,
      'pubgId': pubgId,
      'freefireId': freefireId,
      'photoUrl': photoUrl,
    });
  }

  Future<void> reportUser(String reportedUid, String reporterUid, String reason) async {
    await _db.collection('reports').add({
      'reportedUid': reportedUid,
      'reporterUid': reporterUid,
      'reason': reason,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }
}
