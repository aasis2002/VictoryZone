import 'package:cloud_firestore/cloud_firestore.dart';

class SupportTicketModel {
  final String id;
  final String userId;
  final String userName;
  final String subject;
  final String message;
  final String status; // "open", "in_progress", "resolved"
  final String priority; // "low", "medium", "high"
  final Timestamp timestamp;
  final String? adminReply;

  SupportTicketModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.subject,
    required this.message,
    required this.status,
    required this.priority,
    required this.timestamp,
    this.adminReply,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'subject': subject,
      'message': message,
      'status': status,
      'priority': priority,
      'timestamp': timestamp,
      'adminReply': adminReply,
    };
  }

  factory SupportTicketModel.fromMap(String id, Map<String, dynamic> map) {
    return SupportTicketModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous',
      subject: map['subject'] ?? '',
      message: map['message'] ?? '',
      status: map['status'] ?? 'open',
      priority: map['priority'] ?? 'low',
      timestamp: map['timestamp'] ?? Timestamp.now(),
      adminReply: map['adminReply'],
    );
  }
}
