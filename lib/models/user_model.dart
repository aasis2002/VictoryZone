class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? phoneNumber;
  final String? photoUrl;
  final double walletBalance;
  final double totalWon; // New: Total career winnings
  final double totalWithdrawn; // New: Total amount withdrawn
  final String role; // "user" or "admin"
  final String? pubgId;
  final String? freefireId;
  final int totalMatches;
  final int totalWins;
  final int totalKills;
  final bool isVerified;
  final bool isSuspended;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.photoUrl,
    required this.walletBalance,
    this.totalWon = 0,
    this.totalWithdrawn = 0,
    required this.role,
    this.pubgId,
    this.freefireId,
    this.totalMatches = 0,
    this.totalWins = 0,
    this.totalKills = 0,
    this.isVerified = false,
    this.isSuspended = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'walletBalance': walletBalance,
      'totalWon': totalWon,
      'totalWithdrawn': totalWithdrawn,
      'role': role,
      'pubgId': pubgId,
      'freefireId': freefireId,
      'totalMatches': totalMatches,
      'totalWins': totalWins,
      'totalKills': totalKills,
      'isVerified': isVerified,
      'isSuspended': isSuspended,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      photoUrl: map['photoUrl'],
      walletBalance: (map['walletBalance'] ?? 0).toDouble(),
      totalWon: (map['totalWon'] ?? 0).toDouble(),
      totalWithdrawn: (map['totalWithdrawn'] ?? 0).toDouble(),
      role: map['role'] ?? 'user',
      pubgId: map['pubgId'],
      freefireId: map['freefireId'],
      totalMatches: map['totalMatches'] ?? 0,
      totalWins: map['totalWins'] ?? 0,
      totalKills: map['totalKills'] ?? 0,
      isVerified: map['isVerified'] ?? false,
      isSuspended: map['isSuspended'] ?? false,
    );
  }
}
