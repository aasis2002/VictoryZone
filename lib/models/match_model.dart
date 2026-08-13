import 'package:cloud_firestore/cloud_firestore.dart';

class MatchModel {
  final String matchId;
  final String tournamentId;
  final int roundNumber;
  final String groupName; // e.g., "Group A", "Finals"
  final List<String> playerIds;
  final String status; // "pending", "live", "completed"
  final Map<String, dynamic>? results; // userId -> {rank, kills, points}
  final Timestamp timestamp;

  MatchModel({
    required this.matchId,
    required this.tournamentId,
    required this.roundNumber,
    required this.groupName,
    required this.playerIds,
    required this.status,
    this.results,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'matchId': matchId,
      'tournamentId': tournamentId,
      'roundNumber': roundNumber,
      'groupName': groupName,
      'playerIds': playerIds,
      'status': status,
      'results': results,
      'timestamp': timestamp,
    };
  }

  factory MatchModel.fromMap(Map<String, dynamic> map) {
    return MatchModel(
      matchId: map['matchId'] ?? '',
      tournamentId: map['tournamentId'] ?? '',
      roundNumber: map['roundNumber'] ?? 1,
      groupName: map['groupName'] ?? '',
      playerIds: List<String>.from(map['playerIds'] ?? []),
      status: map['status'] ?? 'pending',
      results: map['results'],
      timestamp: map['timestamp'] ?? Timestamp.now(),
    );
  }
}
