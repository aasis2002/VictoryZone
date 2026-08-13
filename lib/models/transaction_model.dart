import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String txnId;
  final String userId;
  final double amount;
  final String type; // "credit", "debit"
  final String status; // "success", "failed", "pending"
  final String description; // New: Details like "Tournament Entry Fee" or "Refund"
  final String? relatedId; // New: ID of the tournament or wallet request
  final Timestamp timestamp;

  TransactionModel({
    required this.txnId,
    required this.userId,
    required this.amount,
    required this.type,
    required this.status,
    required this.description,
    this.relatedId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'txnId': txnId,
      'userId': userId,
      'amount': amount,
      'type': type,
      'status': status,
      'description': description,
      'relatedId': relatedId,
      'timestamp': timestamp,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      txnId: map['txnId'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      type: map['type'] ?? 'credit',
      status: map['status'] ?? 'pending',
      description: map['description'] ?? '',
      relatedId: map['relatedId'],
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }
}
