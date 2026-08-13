import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/tournament_model.dart';
import '../../services/firestore_service.dart';
import 'admin_winner_selection_screen.dart';
import 'admin_room_info_screen.dart';
import 'admin_matchmaking_screen.dart';
import 'admin_tournament_screen.dart'; // For editing

class AdminManageScreen extends StatelessWidget {
  const AdminManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Match Control Center'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<TournamentModel>>(
        stream: firestore.getAllTournaments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6E00FF)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_esports_outlined, size: 80, color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  const Text('No matches found', style: TextStyle(color: Colors.white24, fontSize: 16)),
                ],
              ),
            );
          }

          final list = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final t = list[index];
              return _AdminTournamentCard(tournament: t);
            },
          );
        },
      ),
    );
  }
}

class _AdminTournamentCard extends StatelessWidget {
  final TournamentModel tournament;
  const _AdminTournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6E00FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.bolt_rounded, color: Color(0xFF6E00FF), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tournament.title, 
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      const SizedBox(height: 2),
                      Text('${tournament.gameType} • ${tournament.gameMode}', 
                           style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
                _StatusChip(status: tournament.status),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white54),
                  color: const Color(0xFF1E293B),
                  onSelected: (val) {
                    if (val == 'edit') {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => AdminTournamentScreen(editTournament: tournament)));
                    } else if (val == 'delete') {
                      _showDeleteDialog(context);
                    }
                  },
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit Info', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'delete', child: Text('Delete match', style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              ],
            ),
          ),

          // Progress Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: StreamBuilder<int>(
              stream: firestore.getRegistrationCount(tournament.id),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Row(
                  children: [
                    const Icon(Icons.people_alt_rounded, size: 14, color: Colors.white38),
                    const SizedBox(width: 8),
                    Text('$count / ${tournament.slots} Joined', 
                         style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Colors.white10),

          // Status Stepper Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Colors.black12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatusActionIcon(
                  icon: Icons.published_with_changes_rounded,
                  label: 'Upcoming',
                  targetStatus: 'published',
                  currentStatus: tournament.status,
                  onTap: () => _updateStatus(context, 'published'),
                ),
                _StatusActionIcon(
                  icon: Icons.play_circle_filled_rounded,
                  label: 'Go Live',
                  targetStatus: 'live',
                  currentStatus: tournament.status,
                  activeColor: Colors.greenAccent,
                  onTap: () => _updateStatus(context, 'live'),
                ),
                _StatusActionIcon(
                  icon: Icons.fact_check_rounded,
                  label: 'Review',
                  targetStatus: 'results_pending',
                  currentStatus: tournament.status,
                  activeColor: Colors.orangeAccent,
                  onTap: () => _updateStatus(context, 'results_pending'),
                ),
                _StatusActionIcon(
                  icon: Icons.check_circle_rounded,
                  label: 'Finish',
                  targetStatus: 'completed',
                  currentStatus: tournament.status,
                  activeColor: Colors.blueAccent,
                  onTap: () => _updateStatus(context, 'completed'),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white10),

          // Quick Actions Section
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (tournament.status == 'live')
                  _ActionButton(
                    icon: Icons.meeting_room_rounded,
                    label: 'ROOM INFO',
                    color: const Color(0xFF00E5FF),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminRoomInfoScreen(tournament: tournament))),
                  ),
                _ActionButton(
                  icon: Icons.grid_view_rounded,
                  label: 'TIE-SHEET',
                  color: Colors.tealAccent,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminMatchmakingScreen(tournament: tournament))),
                ),
                if (tournament.status == 'results_pending')
                  _ActionButton(
                    icon: Icons.emoji_events_rounded,
                    label: 'SET WINNERS',
                    color: const Color(0xFF6E00FF),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminWinnerSelectionScreen(tournament: tournament))),
                  ),
                _ActionButton(
                  icon: Icons.undo_rounded,
                  label: 'REFUND',
                  color: Colors.orangeAccent,
                  isOutlined: true,
                  onTap: () => _showRefundSheet(context),
                ),
                _ActionButton(
                  icon: Icons.cancel_rounded,
                  label: 'CANCEL',
                  color: Colors.redAccent,
                  isOutlined: true,
                  onTap: () => _updateStatus(context, 'cancelled'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Match?', style: TextStyle(color: Colors.white)),
        content: const Text('This will permanently remove the match and all entries. This cannot be undone.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              await FirestoreService().deleteTournament(tournament.id);
              nav.pop();
            }, 
            child: const Text('DELETE', style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }

  void _updateStatus(BuildContext context, String status) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Update Status?', style: TextStyle(color: Colors.white)),
        content: Text('Change match status to ${status.toUpperCase()}?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('CONFIRM', style: TextStyle(color: Color(0xFF00E5FF)))),
        ],
      ),
    );

    if (confirmed == true) {
      await FirestoreService().updateTournamentStatus(tournament.id, status);
      messenger.showSnackBar(
        SnackBar(content: Text('Status updated to $status'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _showRefundSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => _RefundBottomSheet(tournament: tournament),
    );
  }
}

class _StatusActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final String targetStatus;
  final String currentStatus;
  final Color activeColor;
  final VoidCallback onTap;

  const _StatusActionIcon({
    required this.icon,
    required this.label,
    required this.targetStatus,
    required this.currentStatus,
    this.activeColor = const Color(0xFF6E00FF),
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCurrent = currentStatus == targetStatus;
    return GestureDetector(
      onTap: isCurrent ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCurrent ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isCurrent ? activeColor : Colors.white10, size: 26),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(
            color: isCurrent ? activeColor : Colors.white10, 
            fontSize: 10, 
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal
          )),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isOutlined;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.white38;
    String text = status.toUpperCase();

    if (status == 'live') color = Colors.greenAccent;
    if (status == 'results_pending') color = Colors.orangeAccent;
    if (status == 'completed') color = Colors.blueAccent;
    if (status == 'cancelled') color = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }
}

class _RefundBottomSheet extends StatelessWidget {
  final TournamentModel tournament;
  const _RefundBottomSheet({required this.tournament});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 48, color: Colors.orangeAccent),
          const SizedBox(height: 16),
          const Text('Bulk Refund', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('This will restore the Entry Fee to ALL registered players for "${tournament.title}".', 
               textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 32),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('tournaments').doc(tournament.id).collection('entries').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final count = snapshot.data!.docs.length;
              return Column(
                children: [
                  Text('$count Players to be refunded', style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: count == 0 ? null : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        for (var doc in snapshot.data!.docs) {
                          await FirestoreService().processRefund(
                            tournamentId: tournament.id, 
                            userId: doc['userId'], 
                            amount: tournament.entryFee, 
                            entryId: doc.id
                          );
                        }
                        navigator.pop();
                        messenger.showSnackBar(const SnackBar(content: Text('All players refunded successfully!'), backgroundColor: Colors.green));
                      },
                      child: const Text('Confirm Bulk Refund'),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
