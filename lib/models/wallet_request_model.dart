import 'package:cloud_firestore/cloud_firestore.dart';

class WalletRequestModel {
  final String requestId;
  final String userId;
  final double amount;
  final String esewaRefId;
  final String? screenshotUrl; // New: Proof of payment
  final String status; // "pending", "approved", "rejected"
  final Timestamp timestamp;

  WalletRequestModel({
    required this.requestId,
    required this.userId,
    required this.amount,
    required this.esewaRefId,
    this.screenshotUrl,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'userId': userId,
      'amount': amount,
      'esewaRefId': esewaRefId,
      'screenshotUrl': screenshotUrl,
      'status': status,
      'timestamp': timestamp,
    };
  }

  factory WalletRequestModel.fromMap(Map<String, dynamic> map) {
    return WalletRequestModel(
      requestId: map['requestId'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      esewaRefId: map['esewaRefId'] ?? '',
      screenshotUrl: map['screenshotUrl'],
      status: map['status'] ?? 'pending',
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }
}
