import 'package:cloud_firestore/cloud_firestore.dart';

class InvitationModel {
  final String id;
  final String teamId;
  final String teamName;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String status; // "pending", "accepted", "rejected"
  final Timestamp timestamp;

  InvitationModel({
    required this.id,
    required this.teamId,
    required this.teamName,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamId': teamId,
      'teamName': teamName,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'status': status,
      'timestamp': timestamp,
    };
  }

  factory InvitationModel.fromMap(String id, Map<String, dynamic> map) {
    return InvitationModel(
      id: id,
      teamId: map['teamId'] ?? '',
      teamName: map['teamName'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      status: map['status'] ?? 'pending',
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }
}
