import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/team_model.dart';
import '../models/invitation_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class TeamProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  Future<void> createTeam(String name, String leaderId, String gameType, {String? logoUrl}) async {
    _isLoading = true;
    notifyListeners();
    try {
      final team = TeamModel(
        id: const Uuid().v4(),
        name: name,
        leaderId: leaderId,
        memberIds: [leaderId],
        gameType: gameType,
        logoUrl: logoUrl,
      );
      await _firestoreService.createTeam(team);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateTeam(String teamId, String name, String? logoUrl) async {
    await _firestoreService.updateTeamProfile(teamId, name, logoUrl);
  }

  Future<void> invitePlayer({
    required String teamId,
    required String teamName,
    required String senderId,
    required String senderName,
    required String receiverId,
  }) async {
    final invitation = InvitationModel(
      id: const Uuid().v4(),
      teamId: teamId,
      teamName: teamName,
      senderId: senderId,
      senderName: senderName,
      receiverId: receiverId,
      status: 'pending',
      timestamp: Timestamp.now(),
    );
    await _firestoreService.invitePlayer(invitation);
  }

  Future<void> respondToInvitation(String invitationId, String status, String teamId, String userId) async {
    await _firestoreService.respondToInvitation(invitationId, status, teamId, userId);
  }

  Future<void> removeMember(String teamId, String userId) async {
    await _firestoreService.removeMember(teamId, userId);
  }

  Future<void> leaveTeam(String teamId, String userId) async {
    await _firestoreService.leaveTeam(teamId, userId);
  }

  Future<void> transferCaptain(String teamId, String newLeaderId) async {
    await _firestoreService.transferCaptain(teamId, newLeaderId);
  }

  Future<List<UserModel>> searchPlayers(String query) async {
    return await _firestoreService.searchUsers(query);
  }

  Future<List<UserModel>> getTeamMembers(List<String> memberIds) async {
    return await _firestoreService.getTeamMembers(memberIds);
  }
}
