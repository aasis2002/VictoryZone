import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/dispute_model.dart';
import '../../services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminDisputeListScreen extends StatelessWidget {
  const AdminDisputeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text('Dispute Center')),
      body: StreamBuilder<List<DisputeModel>>(
        stream: firestore.getAllDisputes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No active disputes', style: TextStyle(color: Colors.white24)));
          }

          final list = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final dispute = list[index];
              return _DisputeCard(dispute: dispute);
            },
          );
        },
      ),
    );
  }
}

class _DisputeCard extends StatelessWidget {
  final DisputeModel dispute;
  const _DisputeCard({required this.dispute});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: dispute.status == 'pending' ? Colors.redAccent.withValues(alpha: 0.2) : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusBadge(dispute.status),
              Text(DateFormat('dd MMM, hh:mm a').format(dispute.timestamp.toDate()), 
                   style: const TextStyle(color: Colors.white24, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 16),
          Text(dispute.reason, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(dispute.description, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 16),
          if (dispute.evidenceUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: dispute.evidenceUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: Colors.black26),
              ),
            ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleAction(context, 'dismissed'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white54),
                  child: const Text('Dismiss'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showTakeActionDialog(context),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  child: const Text('Enforce'),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String status) async {
    await FirestoreService().updateDisputeStatus(dispute.id, status, 'Resolved by Admin');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dispute marked as $status')));
  }

  void _showTakeActionDialog(BuildContext context) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Enforcement Action', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose a penalty for the reported user.', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Admin comment/reason', hintStyle: TextStyle(color: Colors.white24)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              await FirestoreService().disqualifyPlayer(dispute.tournamentId, dispute.reportedUserId, commentController.text);
              await FirestoreService().updateDisputeStatus(dispute.id, 'resolved', 'Player Disqualified');
              nav.pop();
            },
            child: const Text('DISQUALIFY'),
          ),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              await FirestoreService().toggleUserBan(dispute.reportedUserId, true, commentController.text);
              await FirestoreService().updateDisputeStatus(dispute.id, 'resolved', 'User Banned');
              nav.pop();
            },
            child: const Text('PERMANENT BAN', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.orangeAccent;
    if (status == 'resolved') color = Colors.greenAccent;
    if (status == 'dismissed') color = Colors.white24;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}
