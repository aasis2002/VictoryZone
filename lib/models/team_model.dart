class TeamModel {
  final String id;
  final String name;
  final String leaderId;
  final List<String> memberIds;
  final String gameType; // "PUBG Mobile", "Free Fire", etc.
  final String? logoUrl;

  TeamModel({
    required this.id,
    required this.name,
    required this.leaderId,
    required this.memberIds,
    required this.gameType,
    this.logoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'leaderId': leaderId,
      'memberIds': memberIds,
      'gameType': gameType,
      'logoUrl': logoUrl,
    };
  }

  factory TeamModel.fromMap(String id, Map<String, dynamic> map) {
    return TeamModel(
      id: id,
      name: map['name'] ?? '',
      leaderId: map['leaderId'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      gameType: map['gameType'] ?? '',
      logoUrl: map['logoUrl'],
    );
  }
}
