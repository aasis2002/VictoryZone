import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/tournament_model.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';

class AdminWinnerSelectionScreen extends StatefulWidget {
  final TournamentModel tournament;
  const AdminWinnerSelectionScreen({super.key, required this.tournament});

  @override
  State<AdminWinnerSelectionScreen> createState() => _AdminWinnerSelectionScreenState();
}

class _AdminWinnerSelectionScreenState extends State<AdminWinnerSelectionScreen> {
  final FirestoreService _firestore = FirestoreService();
  final Map<String, int> _playerKills = {};
  final Map<String, int> _playerRank = {};
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text('Submit Match Results')),
      body: StreamBuilder<List<TournamentEntry>>(
        stream: _firestore.getTournamentEntries(widget.tournament.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final entries = snapshot.data!;

          if (entries.isEmpty) return const Center(child: Text('No participants joined', style: TextStyle(color: Colors.white24)));

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF6E00FF).withValues(alpha: 0.1),
                child: const Text(
                  'Enter final rank and total kills for each player.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: entries.length,
                  itemBuilder: (ctx, index) {
                    final entry = entries[index];
                    return _buildParticipantResultCard(entry);
                  },
                ),
              ),
              _buildBottomActions(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildParticipantResultCard(TournamentEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.person, color: Colors.white38)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('User: ${entry.userId.substring(0, 8)}...', 
                         style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    if (entry.submittedKills != null)
                      Text('User Claims: ${entry.submittedKills} Kills', 
                           style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (entry.screenshotUrl != null)
                IconButton(
                  icon: const Icon(Icons.image_rounded, color: Color(0xFF00E5FF)),
                  onPressed: () => _showProof(entry.screenshotUrl!),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('Final Rank', Icons.emoji_events_rounded),
                  onChanged: (val) => _playerRank[entry.userId] = int.tryParse(val) ?? 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDeco('Actual Kills', Icons.military_tech_rounded),
                  onChanged: (val) => _playerKills[entry.userId] = int.tryParse(val) ?? 0,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 16, color: Colors.white24),
      filled: true,
      fillColor: Colors.black26,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Color(0xFF1E293B), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: _isSubmitting 
        ? const Center(child: CircularProgressIndicator())
        : ElevatedButton(
            onPressed: _submitFinalResults,
            child: const Text('FINALIZE RESULTS & PAYOUT'),
          ),
    );
  }

  void _submitFinalResults() async {
    if (_playerRank.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter results for at least one player.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // We also prepare the "winners" map for the tournament document
      final Map<String, String> winnersMap = {};

      for (var userId in _playerRank.keys) {
        int rank = _playerRank[userId]!;
        int kills = _playerKills[userId] ?? 0;

        // Calculate Points based on Tournament Config
        double killPts = kills * widget.tournament.pointsPerKill;
        double placementPts = (widget.tournament.placementPointsConfig[rank.toString()] ?? 0).toDouble();
        double totalPts = killPts + placementPts;

        if (rank <= 3 && rank > 0) {
          winnersMap[rank.toString()] = userId;
        }

        final entryQuery = await FirebaseFirestore.instance
            .collection('tournaments').doc(widget.tournament.id)
            .collection('entries')
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

        if (entryQuery.docs.isNotEmpty) {
          final entryRef = entryQuery.docs.first.reference;
          
          final resultData = {
            'rank': rank,
            'kills': kills,
            'killPoints': killPts,
            'placementPoints': placementPts,
            'totalPoints': totalPts,
            'status': 'completed',
          };

          batch.update(entryRef, resultData);
          
          // Also update the user's copy
          batch.update(
            FirebaseFirestore.instance.collection('users').doc(userId)
            .collection('my_entries').doc(widget.tournament.id),
            resultData
          );

          // NEW: Sync Career Stats
          final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
          batch.update(userRef, {
            'totalKills': FieldValue.increment(kills),
            'totalMatches': FieldValue.increment(1),
            'totalWins': FieldValue.increment(rank == 1 ? 1 : 0),
          });
        }
      }

      // Update tournament status
      batch.update(
        FirebaseFirestore.instance.collection('tournaments').doc(widget.tournament.id),
        {
          'status': 'completed',
          'winners': winnersMap,
          'prizeStatus': 'pending_payout', // This triggers the (future) cloud function
        }
      );

      await batch.commit();

      // Notify all players about results
      await _firestore.notifyTournamentPlayers(
        tournamentId: widget.tournament.id,
        title: 'Results Published!',
        body: 'Final rankings for ${widget.tournament.title} are out. Check the leaderboard!',
        type: 'tournament',
      );

      // Notify Top 3 specifically (Prize Credited placeholder)
      for (var entry in winnersMap.entries) {
        final rank = entry.key;
        final uid = entry.value;
        await NotificationService.sendAndLogNotification(
          userId: uid,
          title: 'Victory Achievement!',
          body: 'Congratulations! You secured Rank #$rank in ${widget.tournament.title}. Your prize is being processed.',
          type: 'tournament',
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Results finalized successfully!'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error finalizing: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showProof(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.network(url),
        ),
      ),
    );
  }
}
