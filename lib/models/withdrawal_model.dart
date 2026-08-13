import 'package:cloud_firestore/cloud_firestore.dart';

class WithdrawalModel {
  final String requestId;
  final String userId;
  final double amount;
  final String esewaId;
  final String status; // "pending", "approved", "rejected", "completed"
  final Timestamp timestamp;

  WithdrawalModel({
    required this.requestId,
    required this.userId,
    required this.amount,
    required this.esewaId,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'userId': userId,
      'amount': amount,
      'esewaId': esewaId,
      'status': status,
      'timestamp': timestamp,
    };
  }

  factory WithdrawalModel.fromMap(Map<String, dynamic> map) {
    return WithdrawalModel(
      requestId: map['requestId'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      esewaId: map['esewaId'] ?? '',
      status: map['status'] ?? 'pending',
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }
}
