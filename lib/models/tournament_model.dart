import 'package:cloud_firestore/cloud_firestore.dart';

class TournamentModel {
  final String id;
  final String title;
  final String gameType; 
  final String gameMode; 
  final String date;
  final String time;
  final double entryFee;
  final bool isFree;
  final int maxTeams;
  final int maxPlayers;
  final int slots;
  final String prize; 
  final String imageUrl;
  final String status; // "published", "live", "results_pending", "completed", "cancelled"
  final String? map;
  final String? version;
  final String? description;
  final String? rules;
  final String? registrationStart;
  final String? registrationEnd;
  final String? matchDuration;
  final int? numberOfRounds;

  final double totalPrizePool;
  final double firstPrize;
  final double secondPrize;
  final double thirdPrize;
  final double killReward;
  final double mvpReward;
  final String? otherRewards;

  final String prizeStatus; 
  final Map<String, dynamic>? winners;

  // New: Scoring Configuration
  final double pointsPerKill;
  final Map<String, int> placementPointsConfig;

  TournamentModel({
    required this.id,
    required this.title,
    required this.gameType,
    required this.gameMode,
    required this.date,
    required this.time,
    required this.entryFee,
    this.isFree = false,
    required this.maxTeams,
    required this.maxPlayers,
    required this.slots,
    required this.prize,
    required this.imageUrl,
    required this.status,
    this.map,
    this.version,
    this.description,
    this.rules,
    this.registrationStart,
    this.registrationEnd,
    this.matchDuration,
    this.numberOfRounds,
    this.totalPrizePool = 0,
    this.firstPrize = 0,
    this.secondPrize = 0,
    this.thirdPrize = 0,
    this.killReward = 0,
    this.mvpReward = 0,
    this.otherRewards,
    this.prizeStatus = 'none',
    this.winners,
    this.pointsPerKill = 1.0,
    this.placementPointsConfig = const {
      '1': 15, '2': 12, '3': 10, '4': 8, '5': 6, 
      '6': 4, '7': 2, '8': 1, '9': 1, '10': 1
    },
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'gameType': gameType,
      'gameMode': gameMode,
      'date': date,
      'time': time,
      'entryFee': entryFee,
      'isFree': isFree,
      'maxTeams': maxTeams,
      'maxPlayers': maxPlayers,
      'slots': slots,
      'prize': prize,
      'imageUrl': imageUrl,
      'status': status,
      'map': map,
      'version': version,
      'description': description,
      'rules': rules,
      'registrationStart': registrationStart,
      'registrationEnd': registrationEnd,
      'matchDuration': matchDuration,
      'numberOfRounds': numberOfRounds,
      'totalPrizePool': totalPrizePool,
      'firstPrize': firstPrize,
      'secondPrize': secondPrize,
      'thirdPrize': thirdPrize,
      'killReward': killReward,
      'mvpReward': mvpReward,
      'otherRewards': otherRewards,
      'prizeStatus': prizeStatus,
      'winners': winners,
      'pointsPerKill': pointsPerKill,
      'placementPointsConfig': placementPointsConfig,
    };
  }

  factory TournamentModel.fromMap(String id, Map<String, dynamic> map) {
    return TournamentModel(
      id: id,
      title: map['title'] ?? '',
      gameType: map['gameType'] ?? '',
      gameMode: map['gameMode'] ?? 'Solo',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      entryFee: (map['entryFee'] ?? 0).toDouble(),
      isFree: map['isFree'] ?? false,
      maxTeams: map['maxTeams'] ?? 0,
      maxPlayers: map['maxPlayers'] ?? 0,
      slots: map['slots'] ?? 0,
      prize: map['prize'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      status: map['status'] ?? 'published',
      map: map['map'],
      version: map['version'],
      description: map['description'],
      rules: map['rules'],
      registrationStart: map['registrationStart'],
      registrationEnd: map['registrationEnd'],
      matchDuration: map['matchDuration'],
      numberOfRounds: map['numberOfRounds'],
      totalPrizePool: (map['totalPrizePool'] ?? 0).toDouble(),
      firstPrize: (map['firstPrize'] ?? 0).toDouble(),
      secondPrize: (map['secondPrize'] ?? 0).toDouble(),
      thirdPrize: (map['thirdPrize'] ?? 0).toDouble(),
      killReward: (map['killReward'] ?? 0).toDouble(),
      mvpReward: (map['mvpReward'] ?? 0).toDouble(),
      otherRewards: map['otherRewards'],
      prizeStatus: map['prizeStatus'] ?? 'none',
      winners: map['winners'] != null ? Map<String, dynamic>.from(map['winners']) : null,
      pointsPerKill: (map['pointsPerKill'] ?? 1.0).toDouble(),
      placementPointsConfig: Map<String, int>.from(map['placementPointsConfig'] ?? {}),
    );
  }
}

class TournamentEntry {
  final String entryId;
  final String tournamentId;
  final String userId;
  final String status; // "confirmed", "cancelled", "completed", "refunded"
  final double paidAmount;
  final String? matchId;
  final String? matchPassword;
  final String? screenshotUrl;
  final String? submittedKills;
  
  // Result Fields
  final int? rank;
  final int? kills;
  final double? killPoints;
  final double? placementPoints;
  final double? totalPoints;
  final double? winnings;
  final Timestamp? resultTimestamp;

  TournamentEntry({
    required this.entryId,
    required this.tournamentId,
    required this.userId,
    required this.status,
    required this.paidAmount,
    this.matchId,
    this.matchPassword,
    this.screenshotUrl,
    this.submittedKills,
    this.rank,
    this.kills,
    this.killPoints,
    this.placementPoints,
    this.totalPoints,
    this.winnings,
    this.resultTimestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'entryId': entryId,
      'tournamentId': tournamentId,
      'userId': userId,
      'status': status,
      'paidAmount': paidAmount,
      'matchId': matchId,
      'matchPassword': matchPassword,
      'screenshotUrl': screenshotUrl,
      'submittedKills': submittedKills,
      'rank': rank,
      'kills': kills,
      'killPoints': killPoints,
      'placementPoints': placementPoints,
      'totalPoints': totalPoints,
      'winnings': winnings,
      'resultTimestamp': resultTimestamp,
    };
  }

  factory TournamentEntry.fromMap(Map<String, dynamic> map) {
    return TournamentEntry(
      entryId: map['entryId'] ?? '',
      tournamentId: map['tournamentId'] ?? '',
      userId: map['userId'] ?? '',
      status: map['status'] ?? 'confirmed',
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      matchId: map['matchId'],
      matchPassword: map['matchPassword'],
      screenshotUrl: map['screenshotUrl'],
      submittedKills: map['submittedKills'],
      rank: map['rank'],
      kills: map['kills'],
      killPoints: (map['killPoints'] ?? 0).toDouble(),
      placementPoints: (map['placementPoints'] ?? 0).toDouble(),
      totalPoints: (map['totalPoints'] ?? 0).toDouble(),
      winnings: (map['winnings'] ?? 0).toDouble(),
      resultTimestamp: map['resultTimestamp'],
    );
  }
}
