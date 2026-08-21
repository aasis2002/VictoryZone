import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../core/theme.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('GLOBAL RANKINGS'),
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestore.getGlobalLeaderboard(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('NO INTEL AVAILABLE YET', style: TextStyle(color: Colors.white24, letterSpacing: 2)),
            );
          }

          final players = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              final rank = index + 1;
              
              return _buildRankCard(player, rank);
            },
          );
        },
      ),
    );
  }

  Widget _buildRankCard(UserModel player, int rank) {
    bool isTopThree = rank <= 3;
    Color rankColor = Colors.white24;
    IconData? rankIcon;

    if (rank == 1) {
      rankColor = Colors.amberAccent;
      rankIcon = Icons.emoji_events_rounded;
    } else if (rank == 2) {
      rankColor = const Color(0xFFE2E8F0); // Silver
      rankIcon = Icons.emoji_events_rounded;
    } else if (rank == 3) {
      rankColor = Colors.orangeAccent;
      rankIcon = Icons.emoji_events_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isTopThree ? rankColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
          width: isTopThree ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: isTopThree 
              ? Icon(rankIcon, color: rankColor, size: 28)
              : Text('#$rank', style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            backgroundImage: player.photoUrl != null ? NetworkImage(player.photoUrl!) : null,
            child: player.photoUrl == null ? const Icon(Icons.person, color: Colors.white24) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${player.totalKills} TOTAL FRAGS',
                  style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs. ${player.totalWon.toInt()}',
                style: TextStyle(color: isTopThree ? rankColor : AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Text('EARNED', style: TextStyle(color: Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
