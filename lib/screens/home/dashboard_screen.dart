import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/firestore_service.dart';
import '../../core/theme.dart';
import 'notification_screen.dart';
import 'my_teams_screen.dart';
import 'admin_dashboard_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final nav = Provider.of<NavigationProvider>(context, listen: false);
    final firestore = FirestoreService();
    final user = auth.userModel;

    if (user == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text('DASHBOARD'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, size: 28),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              _buildWelcomeCard(user),
              const SizedBox(height: 32),

              // Quick Stats
              _sectionHeader('PERFORMANCE'),
              const SizedBox(height: 16),
              Row(
                children: [
                  _statCard('TOTAL WON', 'Rs. ${user.totalWon.toInt()}', Icons.emoji_events_rounded, Colors.amberAccent),
                  const SizedBox(width: 16),
                  _statCard('MATCHES', user.totalMatches.toString(), Icons.sports_esports_rounded, AppTheme.primaryColor),
                ],
              ),
              const SizedBox(height: 32),

              // Navigation Grid
              _sectionHeader('QUICK ACCESS'),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _menuCard('MY TEAMS', Icons.group_rounded, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyTeamsScreen()));
                  }, const Color(0xFF6366F1)),
                  _menuCard('RESULTS', Icons.assignment_turned_in_rounded, () {
                    nav.setIndex(2); // Go to Events tab
                  }, const Color(0xFF10B981)),
                  _menuCard('WALLET', Icons.account_balance_wallet_rounded, () {
                    nav.setIndex(3); // Go to Wallet tab
                  }, const Color(0xFFF59E0B)),
                  _menuCard('STATISTICS', Icons.bar_chart_rounded, () {
                    nav.setIndex(4); // Go to Profile for stats
                  }, const Color(0xFFEC4899)),
                ],
              ),
              const SizedBox(height: 32),

              if (user.role == 'admin') ...[
                _sectionHeader('ADMINISTRATION'),
                const SizedBox(height: 16),
                _adminGateway(context),
                const SizedBox(height: 32),
              ],
              
              _sectionHeader('RECENT ACTIVITY'),
              const SizedBox(height: 16),
              _buildRecentActivity(user.uid, firestore),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SOLDIER, WELCOME BACK', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(user.name.toUpperCase(), 
               style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user_rounded, size: 16, color: AppTheme.accentColor),
                const SizedBox(width: 8),
                Text(user.isVerified ? 'VERIFIED VETERAN' : 'ELITE COMPETITOR', 
                     style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 20),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(String title, IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _adminGateway(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              backgroundColor: AppTheme.accentColor,
              child: Icon(Icons.admin_panel_settings_rounded, color: Colors.black),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('COMMAND CENTER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  Text('Platform monitoring & control', style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(String uid, FirestoreService firestore) {
    return StreamBuilder(
      stream: firestore.getJoinedEvents(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: const Text('NO RECENT MISSIONS', textAlign: TextAlign.center, style: TextStyle(color: Colors.white12, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 2)),
          );
        }
        return Column(
          children: snapshot.data!.take(3).map((item) {
            final t = item['tournament'];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.military_tech_rounded, size: 20, color: AppTheme.accentColor),
                ),
                title: Text(t.title.toUpperCase(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                subtitle: Text('JOINED ON ${t.date}', style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white10),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5)),
      ],
    );
  }
}
