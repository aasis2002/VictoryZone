import 'package:cloud_firestore/cloud_firestore.dart';

class DisputeModel {
  final String id;
  final String tournamentId;
  final String reporterId;
  final String reportedUserId;
  final String reason; // e.g., "Hacking", "Teaming", "Toxic Behavior"
  final String description;
  final String? evidenceUrl;
  final String status; // "pending", "investigating", "resolved", "dismissed"
  final String? adminComment;
  final Timestamp timestamp;

  DisputeModel({
    required this.id,
    required this.tournamentId,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    required this.description,
    this.evidenceUrl,
    required this.status,
    this.adminComment,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason,
      'description': description,
      'evidenceUrl': evidenceUrl,
      'status': status,
      'adminComment': adminComment,
      'timestamp': timestamp,
    };
  }

  factory DisputeModel.fromMap(String id, Map<String, dynamic> map) {
    return DisputeModel(
      id: id,
      tournamentId: map['tournamentId'] ?? '',
      reporterId: map['reporterId'] ?? '',
      reportedUserId: map['reportedUserId'] ?? '',
      reason: map['reason'] ?? '',
      description: map['description'] ?? '',
      evidenceUrl: map['evidenceUrl'],
      status: map['status'] ?? 'pending',
      adminComment: map['adminComment'],
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }
}
