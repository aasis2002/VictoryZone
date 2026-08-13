import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/team_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/notification_model.dart';
import '../../models/invitation_model.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final teamProvider = Provider.of<TeamProvider>(context);
    final firestore = FirestoreService();

    if (auth.userModel == null) return const Scaffold();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          bottom: const TabBar(
            indicatorColor: Color(0xFF00E5FF),
            labelColor: Color(0xFF00E5FF),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(text: 'General'),
              Tab(text: 'Invitations'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildGeneralNotifications(auth.userModel!.uid, firestore),
            _buildTeamInvitations(auth.userModel!.uid, firestore, teamProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralNotifications(String uid, FirestoreService firestore) {
    return StreamBuilder<List<NotificationModel>>(
      stream: firestore.getUserNotifications(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _emptyState('No notifications yet', Icons.notifications_off_rounded);
        }

        final list = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final n = list[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: n.isRead ? Colors.transparent : const Color(0xFF6E00FF).withValues(alpha: 0.3)),
              ),
              child: ListTile(
                onTap: () => firestore.markNotificationAsRead(uid, n.id),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: _getColor(n.type).withValues(alpha: 0.1),
                  child: Icon(_getIcon(n.type), color: _getColor(n.type), size: 20),
                ),
                title: Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold, fontSize: 16, color: Colors.white)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(n.body, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('hh:mm a • dd MMM').format(n.timestamp.toDate()),
                      style: const TextStyle(color: Colors.white24, fontSize: 10),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTeamInvitations(String uid, FirestoreService firestore, TeamProvider provider) {
    return StreamBuilder<List<InvitationModel>>(
      stream: firestore.getUserInvitations(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _emptyState('No pending invitations', Icons.group_add_rounded);
        }

        final list = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final inv = list[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.group_rounded, color: Color(0xFF6E00FF))),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(inv.teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                            Text('Invited by ${inv.senderName}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => provider.respondToInvitation(inv.id, 'rejected', inv.teamId, uid),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white10)),
                          child: const Text('Reject', style: TextStyle(color: Colors.white70)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => provider.respondToInvitation(inv.id, 'accepted', inv.teamId, uid),
                          child: const Text('Accept'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          Text(text, style: const TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'tournament': return Icons.emoji_events_rounded;
      case 'wallet': return Icons.account_balance_wallet_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _getColor(String? type) {
    switch (type) {
      case 'tournament': return const Color(0xFF00E5FF);
      case 'wallet': return const Color(0xFF00C853);
      default: return const Color(0xFF6E00FF);
    }
  }
}
