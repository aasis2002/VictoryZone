import 'package:flutter/material.dart';
import '../../models/tournament_model.dart';
import '../../models/match_model.dart';
import '../../services/firestore_service.dart';
import '../../core/theme.dart';

class AdminMatchmakingScreen extends StatefulWidget {
  final TournamentModel tournament;
  const AdminMatchmakingScreen({super.key, required this.tournament});

  @override
  State<AdminMatchmakingScreen> createState() => _AdminMatchmakingScreenState();
}

class _AdminMatchmakingScreenState extends State<AdminMatchmakingScreen> {
  final _lobbySizeController = TextEditingController(text: '25');
  final _topQualifiersController = TextEditingController(text: '10');
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text('TIE-SHEET GENERATOR')),
      body: StreamBuilder<List<MatchModel>>(
        stream: firestore.getTournamentMatches(widget.tournament.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final matches = snapshot.data!;

          return Column(
            children: [
              _buildGeneratorHeader(matches),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: matches.length,
                  itemBuilder: (ctx, index) {
                    final match = matches[index];
                    return _buildMatchCard(match);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGeneratorHeader(List<MatchModel> matches) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: AppTheme.cardColor,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _lobbySizeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'PLAYERS PER LOBBY', labelStyle: TextStyle(fontSize: 10)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _generateInitialGroups,
                  child: const Text('GENERATE RD 1', style: TextStyle(fontSize: 10)),
                ),
              ),
            ],
          ),
          if (matches.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _topQualifiersController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'TOP N TO QUALIFY', labelStyle: TextStyle(fontSize: 10)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _advanceRound(matches),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: const Text('ADVANCE RD', style: TextStyle(fontSize: 10)),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildMatchCard(MatchModel match) {
    final playersString = match.playerIds.join(', ');
    final displayPlayers = playersString.length > 100 
        ? '${playersString.substring(0, 100)}...' 
        : playersString;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ROUND ${match.roundNumber} - ${match.groupName}', 
                   style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
              Text('${match.playerIds.length} PLAYERS', style: const TextStyle(color: AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(displayPlayers,
               style: const TextStyle(color: Colors.white24, fontSize: 11)),
        ],
      ),
    );
  }

  void _generateInitialGroups() async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final size = int.tryParse(_lobbySizeController.text) ?? 25;
      await FirestoreService().generateInitialGroups(
        tournamentId: widget.tournament.id, 
        playersPerLobby: size
      );
      messenger.showSnackBar(const SnackBar(content: Text('Initial groups generated!')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _advanceRound(List<MatchModel> matches) async {
    setState(() => _isLoading = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final currentRound = matches.map((m) => m.roundNumber).reduce((a, b) => a > b ? a : b);
      final topN = int.tryParse(_topQualifiersController.text) ?? 10;
      await FirestoreService().advanceQualifiedPlayers(
        tournamentId: widget.tournament.id, 
        currentRound: currentRound, 
        topNToQualify: topN
      );
      messenger.showSnackBar(const SnackBar(content: Text('Next round generated!')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
