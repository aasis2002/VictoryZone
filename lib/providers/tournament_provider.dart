import 'package:flutter/material.dart';
import '../models/tournament_model.dart';
import '../services/firestore_service.dart';

class TournamentProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  
  List<TournamentModel> _allTournaments = [];
  String _searchQuery = '';

  List<TournamentModel> get tournaments {
    if (_searchQuery.isEmpty) {
      return _allTournaments;
    }
    return _allTournaments
        .where((t) => t.title.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                     t.gameType.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void updateTournaments(List<TournamentModel> list) {
    _allTournaments = list;
    // notifyListeners() is usually handled by StreamBuilder but we keep it for consistency
  }

  Future<void> joinTournament(String tournamentId, String userId, double fee) async {
    await _firestoreService.joinTournament(tournamentId, userId, fee);
  }
}
