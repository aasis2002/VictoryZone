import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/tournament_model.dart';
import '../models/transaction_model.dart';
import '../models/wallet_request_model.dart';
import '../models/app_config_model.dart';
import '../models/team_model.dart';
import '../models/notification_model.dart';
import '../models/invitation_model.dart';
import '../models/withdrawal_model.dart';
import '../models/dispute_model.dart';
import '../models/match_model.dart';
import '../models/user_model.dart';
import '../core/constants.dart';

import 'notification_service.dart';

import '../models/support_ticket_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Initialization Logic ---
  Future<void> initializeApp() async {
    // 1. Check Config
    var configDoc = await _db.collection(AppConstants.configColl).doc(AppConstants.configDocId).get();
    if (!configDoc.exists) {
      await _db.collection(AppConstants.configColl).doc(AppConstants.configDocId).set({
        'esewaId': '9800000000',
        'qrCodeUrl': 'https://firebasestorage.googleapis.com/v0/b/victory-zone-app.appspot.com/o/sample_qr.png?alt=media',
      });
    }

    // 2. Check and add sample tournaments
    var pubgQuery = await _db.collection(AppConstants.tournamentsColl)
        .where('gameType', isEqualTo: 'PUBG Mobile').limit(1).get();
    if (pubgQuery.docs.isEmpty) {
      String id = const Uuid().v4();
      await _db.collection(AppConstants.tournamentsColl).doc(id).set({
        'id': id,
        'title': 'PUBG Mobile Weekly Cup',
        'gameType': 'PUBG Mobile',
        'gameMode': 'Squad',
        'date': '2026-08-20',
        'time': '18:00',
        'entryFee': 100,
        'isFree': false,
        'maxTeams': 25,
        'maxPlayers': 100,
        'slots': 100,
        'prize': 'Rs. 5000',
        'imageUrl': 'https://firebasestorage.googleapis.com/v0/b/victory-zone-app.appspot.com/o/pubg_banner.jpg?alt=media',
        'status': 'published',
        'map': 'Erangle',
        'version': 'v3.2',
        'description': 'Join the weekly squad battle.',
        'rules': '1. No emulators.\n2. Team up strictly prohibited.',
        'registrationStart': '2026-08-15',
        'registrationEnd': '2026-08-19',
        'matchDuration': '30 mins',
        'numberOfRounds': 3,
        'totalPrizePool': 5000,
        'firstPrize': 2500,
        'secondPrize': 1500,
        'thirdPrize': 500,
        'killReward': 10,
        'mvpReward': 200,
        'otherRewards': 'Winner Winner Chicken Dinner!',
      });
    }

    var ffQuery = await _db.collection(AppConstants.tournamentsColl)
        .where('gameType', isEqualTo: 'Free Fire').limit(1).get();
    if (ffQuery.docs.isEmpty) {
      String id = const Uuid().v4();
      await _db.collection(AppConstants.tournamentsColl).doc(id).set({
        'id': id,
        'title': 'Free Fire Booyah Championship',
        'gameType': 'Free Fire',
        'gameMode': 'Solo',
        'date': '2026-08-22',
        'time': '14:00',
        'entryFee': 0,
        'isFree': true,
        'maxTeams': 48,
        'maxPlayers': 48,
        'slots': 48,
        'prize': 'Rs. 3000',
        'imageUrl': 'https://firebasestorage.googleapis.com/v0/b/victory-zone-app.appspot.com/o/ff_banner.jpg?alt=media',
        'status': 'published',
        'map': 'Bermuda',
        'version': 'OB44',
        'description': 'Solo championship for pro players.',
        'rules': '1. No hacks.\n2. Respect all players.',
        'registrationStart': '2026-08-16',
        'registrationEnd': '2026-08-21',
        'matchDuration': '20 mins',
        'numberOfRounds': 1,
        'totalPrizePool': 3000,
        'firstPrize': 1500,
        'secondPrize': 1000,
        'thirdPrize': 500,
        'killReward': 5,
        'mvpReward': 100,
        'otherRewards': 'Booyah!',
      });
    }
  }

  Stream<int> getRegistrationCount(String tournamentId) {
    return _db.collection(AppConstants.tournamentsColl)
        .doc(tournamentId)
        .collection('entries')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> createTournament(TournamentModel tournament) async {
    await _db.collection(AppConstants.tournamentsColl).doc(tournament.id).set(tournament.toMap());
  }

  Future<void> updateTournamentStatus(String tournamentId, String newStatus) async {
    await _db.collection(AppConstants.tournamentsColl).doc(tournamentId).update({
      'status': newStatus,
    });

    if (newStatus == 'live') {
      // Notify all players that the match is starting soon/now
      final doc = await _db.collection(AppConstants.tournamentsColl).doc(tournamentId).get();
      final title = doc.data()?['title'] ?? 'Tournament';
      
      await notifyTournamentPlayers(
        tournamentId: tournamentId,
        title: 'Match is LIVE! 🎮',
        body: '$title has started. Check Room Info and join now!',
        type: 'tournament',
      );
    }
  }

  Stream<List<TournamentModel>> getAllTournaments() {
    return _db.collection(AppConstants.tournamentsColl)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TournamentModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // --- App Config ---
  Future<AppConfigModel> getAppConfig() async {
    var doc = await _db.collection(AppConstants.configColl).doc(AppConstants.configDocId).get();
    return AppConfigModel.fromMap(doc.data() as Map<String, dynamic>);
  }

  // --- Tournaments ---
  Stream<List<TournamentModel>> getTournamentsByStatus(String status) {
    return _db
        .collection(AppConstants.tournamentsColl)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TournamentModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<TournamentModel>> getPublishedTournaments() {
    return _db
        .collection(AppConstants.tournamentsColl)
        .where('status', isEqualTo: 'published')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TournamentModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> joinTournament(String tournamentId, String userId, double fee) async {
    var entryCheck = await _db.collection(AppConstants.usersColl)
        .doc(userId)
        .collection('my_entries')
        .doc(tournamentId)
        .get();
        
    if (entryCheck.exists) {
      throw Exception('You have already joined this tournament');
    }

    String entryId = const Uuid().v4();
    
    await _db.runTransaction((transaction) async {
      DocumentReference userRef = _db.collection(AppConstants.usersColl).doc(userId);
      DocumentReference entryRef = _db.collection(AppConstants.tournamentsColl)
          .doc(tournamentId)
          .collection('entries')
          .doc(entryId);
      
      DocumentReference userEntryRef = _db.collection(AppConstants.usersColl)
          .doc(userId)
          .collection('my_entries')
          .doc(tournamentId);

      DocumentReference txnRef = _db.collection(AppConstants.transactionsColl).doc(const Uuid().v4());

      DocumentSnapshot userSnapshot = await transaction.get(userRef);
      double currentBalance = (userSnapshot.get('walletBalance') ?? 0).toDouble();

      if (currentBalance < fee) {
        throw Exception('Insufficient balance');
      }

      transaction.update(userRef, {'walletBalance': currentBalance - fee});
      
      final entryData = {
        'entryId': entryId,
        'tournamentId': tournamentId,
        'userId': userId,
        'status': 'confirmed',
        'paidAmount': fee,
        'matchId': '',
        'matchPassword': '',
        'timestamp': FieldValue.serverTimestamp(),
      };

      transaction.set(entryRef, entryData);
      transaction.set(userEntryRef, entryData);

      transaction.set(txnRef, {
        'txnId': txnRef.id,
        'userId': userId,
        'amount': fee,
        'type': 'debit',
        'status': 'success',
        'description': 'Tournament Entry Fee',
        'relatedId': tournamentId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Notification
      NotificationService.sendAndLogNotification(
        userId: userId,
        title: 'Registration Successful',
        body: 'You have joined the match successfully!',
        type: 'tournament',
      );
    });
  }

  Future<void> processRefund({
    required String tournamentId,
    required String userId,
    required double amount,
    required String entryId,
  }) async {
    await _db.runTransaction((transaction) async {
      DocumentReference userRef = _db.collection(AppConstants.usersColl).doc(userId);
      DocumentReference entryRef = _db.collection(AppConstants.tournamentsColl)
          .doc(tournamentId)
          .collection('entries')
          .doc(entryId);
      DocumentReference userEntryRef = _db.collection(AppConstants.usersColl)
          .doc(userId)
          .collection('my_entries')
          .doc(tournamentId);
      DocumentReference txnRef = _db.collection(AppConstants.transactionsColl).doc(const Uuid().v4());

      DocumentSnapshot userSnapshot = await transaction.get(userRef);
      double currentBalance = (userSnapshot.get('walletBalance') ?? 0).toDouble();

      transaction.update(userRef, {'walletBalance': currentBalance + amount});
      transaction.update(entryRef, {'status': 'refunded'});
      transaction.update(userEntryRef, {'status': 'refunded'});

      transaction.set(txnRef, {
        'txnId': txnRef.id,
        'userId': userId,
        'amount': amount,
        'type': 'credit',
        'status': 'success',
        'description': 'Tournament Refund',
        'relatedId': tournamentId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<Map<String, dynamic>>> getJoinedEvents(String userId) {
    return _db.collection(AppConstants.usersColl)
        .doc(userId)
        .collection('my_entries')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> results = [];
          for (var doc in snapshot.docs) {
            var entryData = doc.data();
            String tId = entryData['tournamentId'];
            var tDoc = await _db.collection(AppConstants.tournamentsColl).doc(tId).get();
            if (tDoc.exists) {
              results.add({
                'entry': entryData,
                'tournament': TournamentModel.fromMap(tDoc.id, tDoc.data() as Map<String, dynamic>),
              });
            }
          }
          return results;
        });
  }

  // --- Wallet ---
  Future<void> submitWalletRequest(WalletRequestModel request) async {
    await _db.collection(AppConstants.walletRequestsColl).doc(request.requestId).set(request.toMap());
  }

  Future<void> submitWithdrawalRequest({
    required String userId,
    required double amount,
    required String esewaId,
  }) async {
    final requestId = const Uuid().v4();
    try {
      await _db.runTransaction((transaction) async {
        DocumentReference userRef = _db.collection(AppConstants.usersColl).doc(userId);
        DocumentReference withdrawalRef = _db.collection('withdrawal_requests').doc(requestId);
        DocumentReference txnRef = _db.collection(AppConstants.transactionsColl).doc(const Uuid().v4());

        DocumentSnapshot userSnapshot = await transaction.get(userRef);
        if (!userSnapshot.exists) throw Exception("User profile not found");

        Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
        double currentBalance = (userData['walletBalance'] ?? 0).toDouble();
        double currentWithdrawn = (userData['totalWithdrawn'] ?? 0).toDouble();

        if (currentBalance < amount) {
          throw Exception('Insufficient balance for withdrawal');
        }

        // Deduct balance and update total withdrawn
        transaction.update(userRef, {
          'walletBalance': currentBalance - amount,
          'totalWithdrawn': currentWithdrawn + amount,
        });

        // Log request
        transaction.set(withdrawalRef, {
          'requestId': requestId,
          'userId': userId,
          'amount': amount,
          'esewaId': esewaId,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Create Transaction
        transaction.set(txnRef, {
          'txnId': txnRef.id,
          'userId': userId,
          'amount': amount,
          'type': 'debit',
          'status': 'success',
          'description': 'Withdrawal to eSewa',
          'relatedId': requestId,
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint("Transaction Error: $e");
      rethrow;
    }
  }

  Stream<List<WithdrawalModel>> getUserWithdrawals(String userId) {
    return _db.collection('withdrawal_requests')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WithdrawalModel.fromMap(doc.data()))
            .toList());
  }

  Stream<List<WithdrawalModel>> getAllWithdrawalRequests() {
    return _db.collection('withdrawal_requests')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WithdrawalModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> updateWithdrawalStatus({
    required String requestId,
    required String newStatus,
    required String userId,
    required double amount,
  }) async {
    await _db.runTransaction((transaction) async {
      DocumentReference userRef = _db.collection(AppConstants.usersColl).doc(userId);
      DocumentReference withdrawalRef = _db.collection('withdrawal_requests').doc(requestId);
      DocumentReference txnRef = _db.collection(AppConstants.transactionsColl).doc(const Uuid().v4());

      // 1. Update the request status
      transaction.update(withdrawalRef, {'status': newStatus});

      // 2. If rejected, refund the user
      if (newStatus == 'rejected') {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);
        double currentBalance = (userSnapshot.get('walletBalance') ?? 0).toDouble();
        double currentWithdrawn = (userSnapshot.get('totalWithdrawn') ?? 0).toDouble();

        transaction.update(userRef, {
          'walletBalance': currentBalance + amount,
          'totalWithdrawn': (currentWithdrawn - amount).clamp(0, double.infinity),
        });

        // Log the refund transaction
        transaction.set(txnRef, {
          'txnId': txnRef.id,
          'userId': userId,
          'amount': amount,
          'type': 'credit',
          'status': 'success',
          'description': 'Withdrawal Rejected (Refund)',
          'relatedId': requestId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        NotificationService.sendAndLogNotification(
          userId: userId,
          title: 'Withdrawal Rejected',
          body: 'Your withdrawal request for Rs. ${amount.toInt()} was rejected. Funds refunded.',
          type: 'wallet',
        );
      } else if (newStatus == 'completed') {
        NotificationService.sendAndLogNotification(
          userId: userId,
          title: 'Withdrawal Completed',
          body: 'Your payout of Rs. ${amount.toInt()} has been processed successfully!',
          type: 'wallet',
        );
      }
    });
  }

  Stream<List<TransactionModel>> getUserTransactions(String userId) {
    return _db
        .collection(AppConstants.transactionsColl)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data()))
            .toList());
  }

  Stream<List<WalletRequestModel>> getUserWalletRequests(String userId) {
    return _db
        .collection(AppConstants.walletRequestsColl)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WalletRequestModel.fromMap(doc.data()))
            .toList());
  }

  Stream<List<WalletRequestModel>> getAllWalletRequests() {
    return _db
        .collection(AppConstants.walletRequestsColl)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WalletRequestModel.fromMap(doc.data()))
            .toList());
  }

  Future<void> updateWalletRequestStatus({
    required String requestId,
    required String newStatus,
    required String userId,
    required double amount,
  }) async {
    await _db.runTransaction((transaction) async {
      DocumentReference userRef = _db.collection(AppConstants.usersColl).doc(userId);
      DocumentReference requestRef = _db.collection(AppConstants.walletRequestsColl).doc(requestId);
      DocumentReference txnRef = _db.collection(AppConstants.transactionsColl).doc(const Uuid().v4());

      // 1. Update request status
      transaction.update(requestRef, {'status': newStatus});

      // 2. If approved, add balance to user
      if (newStatus == 'approved') {
        DocumentSnapshot userSnapshot = await transaction.get(userRef);
        double currentBalance = (userSnapshot.get('walletBalance') ?? 0).toDouble();

        transaction.update(userRef, {'walletBalance': currentBalance + amount});

        // Log the credit transaction
        transaction.set(txnRef, {
          'txnId': txnRef.id,
          'userId': userId,
          'amount': amount,
          'type': 'credit',
          'status': 'success',
          'description': 'eSewa Topup Approved',
          'relatedId': requestId,
          'timestamp': FieldValue.serverTimestamp(),
        });

        NotificationService.sendAndLogNotification(
          userId: userId,
          title: 'Deposit Approved',
          body: 'Rs. ${amount.toInt()} has been credited to your wallet.',
          type: 'wallet',
        );
      } else if (newStatus == 'rejected') {
        NotificationService.sendAndLogNotification(
          userId: userId,
          title: 'Deposit Rejected',
          body: 'Your deposit request for Rs. ${amount.toInt()} was rejected.',
          type: 'wallet',
        );
      }
    });
  }

  Future<void> submitResult({
    required String userId,
    required String tournamentId,
    required String kills,
    required String screenshotUrl,
  }) async {
    final resultData = {
      'status': 'pending_verification',
      'submittedKills': kills,
      'screenshotUrl': screenshotUrl,
      'resultTimestamp': FieldValue.serverTimestamp(),
    };

    await _db.collection(AppConstants.usersColl)
        .doc(userId)
        .collection('my_entries')
        .doc(tournamentId)
        .update(resultData);

    var entryQuery = await _db.collection(AppConstants.tournamentsColl)
        .doc(tournamentId)
        .collection('entries')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    
    if (entryQuery.docs.isNotEmpty) {
      await entryQuery.docs.first.reference.update(resultData);
    }
  }

  // --- Teams ---
  Stream<List<TeamModel>> getUserTeams(String userId) {
    return _db.collection('teams')
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TeamModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> createTeam(TeamModel team) async {
    await _db.collection('teams').doc(team.id).set(team.toMap());
  }

  Future<void> updateTeamProfile(String teamId, String name, String? logoUrl) async {
    await _db.collection('teams').doc(teamId).update({
      'name': name,
      'logoUrl': logoUrl,
    });
  }

  Future<void> invitePlayer(InvitationModel invitation) async {
    await _db.collection('invitations').doc(invitation.id).set(invitation.toMap());
  }

  Stream<List<InvitationModel>> getUserInvitations(String userId) {
    return _db.collection('invitations')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => InvitationModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> respondToInvitation(String invitationId, String status, String teamId, String userId) async {
    await _db.runTransaction((transaction) async {
      DocumentReference invRef = _db.collection('invitations').doc(invitationId);
      DocumentReference teamRef = _db.collection('teams').doc(teamId);

      transaction.update(invRef, {'status': status});

      if (status == 'accepted') {
        transaction.update(teamRef, {
          'memberIds': FieldValue.arrayUnion([userId])
        });
      }
    });
  }

  Future<void> removeMember(String teamId, String userId) async {
    await _db.collection('teams').doc(teamId).update({
      'memberIds': FieldValue.arrayRemove([userId])
    });
  }

  Future<void> leaveTeam(String teamId, String userId) async {
    await removeMember(teamId, userId);
  }

  Future<void> transferCaptain(String teamId, String newLeaderId) async {
    await _db.collection('teams').doc(teamId).update({
      'leaderId': newLeaderId
    });
  }

  Future<List<UserModel>> searchUsers(String query) async {
    // Basic search on name or email
    var snapshot = await _db.collection(AppConstants.usersColl)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(10)
        .get();
    
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  Stream<TeamModel?> getTeamStream(String teamId) {
    return _db.collection('teams').doc(teamId).snapshots().map((doc) {
      if (doc.exists) {
        return TeamModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    });
  }

  Future<List<UserModel>> getTeamMembers(List<String> memberIds) async {
    List<UserModel> members = [];
    for (String id in memberIds) {
      var doc = await _db.collection(AppConstants.usersColl).doc(id).get();
      if (doc.exists) {
        members.add(UserModel.fromMap(doc.data() as Map<String, dynamic>));
      }
    }
    return members;
  }

  // --- Notifications ---
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _db.collection(AppConstants.usersColl)
        .doc(userId)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> markNotificationAsRead(String userId, String notificationId) async {
    await _db.collection(AppConstants.usersColl)
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Stream<List<TournamentEntry>> getTournamentEntries(String tournamentId) {
    return _db.collection(AppConstants.tournamentsColl)
        .doc(tournamentId)
        .collection('entries')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TournamentEntry.fromMap(doc.data()))
            .toList());
  }

  Future<void> notifyTournamentPlayers({
    required String tournamentId,
    required String title,
    required String body,
    required String type,
  }) async {
    final entries = await _db.collection(AppConstants.tournamentsColl)
        .doc(tournamentId)
        .collection('entries')
        .get();
    
    for (var doc in entries.docs) {
      final userId = doc.data()['userId'];
      if (userId != null) {
        NotificationService.sendAndLogNotification(
          userId: userId,
          title: title,
          body: body,
          type: type,
        );
      }
    }
  }

  Future<void> requestTournamentPayout({
    required String tournamentId,
    required Map<String, dynamic> winners,
    required Map<String, int> killsData,
  }) async {
    await _db.collection(AppConstants.tournamentsColl).doc(tournamentId).update({
      'winners': winners,
      'playerKills': killsData,
      'prizeStatus': 'pending_payout',
      'status': 'completed',
      'payoutTriggered': true,
      'payoutTimestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- Anti-Cheat & Disputes ---
  Future<void> submitDispute(DisputeModel dispute) async {
    await _db.collection('disputes').doc(dispute.id).set(dispute.toMap());
    
    // Notify Admins (Internal log or specific channel)
    // For now, we just ensure it's in the DB.
  }

  Stream<List<DisputeModel>> getAllDisputes() {
    return _db.collection('disputes')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DisputeModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> updateDisputeStatus(String id, String status, String? comment) async {
    await _db.collection('disputes').doc(id).update({
      'status': status,
      'adminComment': comment,
    });
  }

  Future<void> disqualifyPlayer(String tournamentId, String userId, String reason) async {
    await _db.runTransaction((transaction) async {
      final entryQuery = await _db.collection(AppConstants.tournamentsColl)
          .doc(tournamentId)
          .collection('entries')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (entryQuery.docs.isNotEmpty) {
        transaction.update(entryQuery.docs.first.reference, {
          'status': 'disqualified',
          'adminComment': reason,
        });

        transaction.update(
          _db.collection(AppConstants.usersColl).doc(userId)
          .collection('my_entries').doc(tournamentId),
          {
            'status': 'disqualified',
            'adminComment': reason,
          }
        );

        NotificationService.sendAndLogNotification(
          userId: userId,
          title: 'Disqualified!',
          body: 'You have been disqualified from the match: $reason',
          type: 'tournament',
        );
      }
    });
  }

  // --- Tie-Sheet / Match Generation ---
  Future<void> generateInitialGroups({
    required String tournamentId,
    required int playersPerLobby,
  }) async {
    final entriesSnapshot = await _db.collection(AppConstants.tournamentsColl)
        .doc(tournamentId)
        .collection('entries')
        .where('status', isEqualTo: 'confirmed')
        .get();

    final List<String> playerIds = entriesSnapshot.docs.map((d) => d.data()['userId'] as String).toList();
    playerIds.shuffle(); // Balanced/Random distribution

    final batch = _db.batch();
    int groupCount = (playerIds.length / playersPerLobby).ceil();

    for (int i = 0; i < groupCount; i++) {
      final start = i * playersPerLobby;
      final end = (start + playersPerLobby > playerIds.length) ? playerIds.length : start + playersPerLobby;
      final groupPlayers = playerIds.sublist(start, end);
      
      final matchId = const Uuid().v4();
      final matchRef = _db.collection(AppConstants.tournamentsColl)
          .doc(tournamentId)
          .collection('matches')
          .doc(matchId);

      final match = MatchModel(
        matchId: matchId,
        tournamentId: tournamentId,
        roundNumber: 1,
        groupName: 'Group ${String.fromCharCode(65 + i)}',
        playerIds: groupPlayers,
        status: 'pending',
        timestamp: Timestamp.now(),
      );

      batch.set(matchRef, match.toMap());
    }

    await batch.commit();
  }

  Stream<List<MatchModel>> getTournamentMatches(String tournamentId) {
    return _db.collection(AppConstants.tournamentsColl)
        .doc(tournamentId)
        .collection('matches')
        .orderBy('roundNumber')
        .orderBy('groupName')
        .snapshots()
        .map((s) => s.docs.map((d) => MatchModel.fromMap(d.data())).toList());
  }

  Future<void> advanceQualifiedPlayers({
    required String tournamentId,
    required int currentRound,
    required int topNToQualify,
  }) async {
    // 1. Get all matches from the current round
    final matchesSnapshot = await _db.collection(AppConstants.tournamentsColl)
        .doc(tournamentId)
        .collection('matches')
        .where('roundNumber', isEqualTo: currentRound)
        .get();

    List<String> qualifiedPlayerIds = [];

    for (var matchDoc in matchesSnapshot.docs) {
      final match = MatchModel.fromMap(matchDoc.data());
      // For each match, we need to find the top players based on the tournament entries data
      // (This assumes results were already finalized for this round)
      final entriesSnapshot = await _db.collection(AppConstants.tournamentsColl)
          .doc(tournamentId)
          .collection('entries')
          .where('userId', whereIn: match.playerIds)
          .get();

      final List<Map<String, dynamic>> playersWithResults = entriesSnapshot.docs.map((d) => d.data()).toList();
      
      // Sort by totalPoints (calculated during finalization)
      playersWithResults.sort((a, b) => (b['totalPoints'] ?? 0).compareTo(a['totalPoints'] ?? 0));
      
      final qualified = playersWithResults.take(topNToQualify).map((p) => p['userId'] as String).toList();
      qualifiedPlayerIds.addAll(qualified);
    }

    if (qualifiedPlayerIds.isEmpty) return;

    // 2. Generate new match for the next round
    final batch = _db.batch();
    final nextRound = currentRound + 1;
    final matchId = const Uuid().v4();
    final matchRef = _db.collection(AppConstants.tournamentsColl)
        .doc(tournamentId)
        .collection('matches')
        .doc(matchId);

    final match = MatchModel(
      matchId: matchId,
      tournamentId: tournamentId,
      roundNumber: nextRound,
      groupName: nextRound == 2 ? 'Finals' : 'Semi-Finals', // Simplification
      playerIds: qualifiedPlayerIds,
      status: 'pending',
      timestamp: Timestamp.now(),
    );

    batch.set(matchRef, match.toMap());
    await batch.commit();
  }

  // --- User Management ---
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _db.collection(AppConstants.usersColl).get();
    return snapshot.docs.map((doc) => UserModel.fromMap(doc.data())).toList();
  }

  Future<void> updateUserRole(String userId, String role) async {
    await _db.collection(AppConstants.usersColl).doc(userId).update({'role': role});
  }

  Future<void> toggleUserBan(String userId, bool isSuspended, String? reason) async {
    await _db.collection(AppConstants.usersColl).doc(userId).update({
      'isSuspended': isSuspended,
      'banReason': isSuspended ? reason : null,
    });
  }

  // --- Tournament Management ---
  Future<void> updateTournament(TournamentModel tournament) async {
    await _db.collection(AppConstants.tournamentsColl).doc(tournament.id).update(tournament.toMap());
  }

  Future<void> deleteTournament(String tournamentId) async {
    // Delete entries first? For now simple delete.
    await _db.collection(AppConstants.tournamentsColl).doc(tournamentId).delete();
  }

  // --- Payment Management ---
  Stream<List<TransactionModel>> getAllTransactions() {
    return _db.collection(AppConstants.transactionsColl)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => TransactionModel.fromMap(d.data())).toList());
  }
  // --- Support Tickets ---
  Future<void> submitSupportTicket(SupportTicketModel ticket) async {
    await _db.collection('support_tickets').doc(ticket.id).set(ticket.toMap());
  }

  Stream<List<SupportTicketModel>> getUserSupportTickets(String userId) {
    return _db.collection('support_tickets')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => SupportTicketModel.fromMap(d.id, d.data())).toList());
  }

  Stream<List<SupportTicketModel>> getAllSupportTickets() {
    return _db.collection('support_tickets')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => SupportTicketModel.fromMap(d.id, d.data())).toList());
  }

  Future<void> updateSupportTicket(String id, String status, String? reply) async {
    await _db.collection('support_tickets').doc(id).update({
      'status': status,
      'adminReply': reply,
    });
  }

  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    final users = await _db.collection(AppConstants.usersColl).get();
    final tournaments = await _db.collection(AppConstants.tournamentsColl).get();
    final withdrawals = await _db.collection('withdrawal_requests').where('status', isEqualTo: 'pending').get();
    final deposits = await _db.collection(AppConstants.walletRequestsColl).where('status', isEqualTo: 'approved').get();

    double totalDeposits = 0;
    for (var doc in deposits.docs) {
      totalDeposits += (doc.data()['amount'] ?? 0).toDouble();
    }

    double totalPrizePool = 0;
    int upcoming = 0;
    int live = 0;
    int completed = 0;
    for (var doc in tournaments.docs) {
      final data = doc.data();
      totalPrizePool += (data['totalPrizePool'] ?? 0).toDouble();
      final status = data['status'];
      if (status == 'published') {
        upcoming++;
      } else if (status == 'live') {
        live++;
      } else if (status == 'completed') {
        completed++;
      }
    }

    final entries = await _db.collectionGroup('entries').get();

    return {
      'totalUsers': users.size,
      'totalTournaments': tournaments.size,
      'upcomingTournaments': upcoming,
      'liveTournaments': live,
      'completedTournaments': completed,
      'pendingWithdrawals': withdrawals.size,
      'totalDeposits': totalDeposits,
      'totalPrizeMoney': totalPrizePool,
      'totalRegistrations': entries.size,
    };
  }

  Stream<double> getTotalWinnings(String userId) {
    return _db.collection(AppConstants.usersColl)
        .doc(userId)
        .collection('my_entries')
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
          double total = 0;
          for (var doc in snapshot.docs) {
            total += (doc.data()['winnings'] ?? 0).toDouble();
          }
          return total;
        });
  }
}
