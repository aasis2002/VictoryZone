import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import 'admin_tournament_screen.dart';
import 'admin_manage_screen.dart';
import 'admin_withdrawal_screen.dart';
import 'admin_deposit_screen.dart';
import 'admin_announcement_screen.dart';
import 'admin_dispute_list_screen.dart';

import 'admin_user_management_screen.dart';
import 'admin_payment_management_screen.dart';
import 'admin_support_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Admin Command Center'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {}), 
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Platform Overview'),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: firestore.getAdminDashboardStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF6E00FF)));
                }
                final stats = snapshot.data!;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _statCard('Total Users', stats['totalUsers'].toString(), Icons.people_rounded, Colors.blueAccent),
                    _statCard('Registrations', stats['totalRegistrations'].toString(), Icons.how_to_reg_rounded, Colors.tealAccent),
                    _statCard('Prize Pool', 'Rs. ${stats['totalPrizeMoney'].toInt()}', Icons.emoji_events_rounded, Colors.amberAccent),
                    _statCard('Deposits', 'Rs. ${stats['totalDeposits'].toInt()}', Icons.account_balance_wallet_rounded, Colors.greenAccent),
                    _statCard('Live Matches', stats['liveTournaments'].toString(), Icons.sensors_rounded, Colors.redAccent),
                    _statCard('Pending Payouts', stats['pendingWithdrawals'].toString(), Icons.payments_rounded, Colors.orangeAccent),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),
            _sectionTitle('Tournament Status'),
            const SizedBox(height: 16),
            FutureBuilder<Map<String, dynamic>>(
              future: firestore.getAdminDashboardStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final stats = snapshot.data!;
                return Row(
                  children: [
                    _miniStatus('Upcoming', stats['upcomingTournaments'].toString(), Colors.white24),
                    const SizedBox(width: 8),
                    _miniStatus('Live', stats['liveTournaments'].toString(), Colors.greenAccent),
                    const SizedBox(width: 8),
                    _miniStatus('Completed', stats['completedTournaments'].toString(), Colors.blueAccent),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),
            _sectionTitle('Management Tools'),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _menuCard('User Accounts', Icons.group_add_rounded, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUserManagementScreen()));
                }, Colors.lightBlue),
                _menuCard('New Tournament', Icons.add_to_photos_rounded, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTournamentScreen()));
                }, const Color(0xFF6E00FF)),
                _menuCard('Manage Matches', Icons.settings_suggest_rounded, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminManageScreen()));
                }, Colors.indigoAccent),
                _menuCard('Payment Ledger', Icons.account_balance_rounded, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPaymentManagementScreen()));
                }, Colors.amber),
                _menuCard('Verify Deposits', Icons.verified_user_rounded, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDepositScreen()));
                }, Colors.teal),
                _menuCard('Process Payouts', Icons.currency_rupee_rounded, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminWithdrawalScreen()));
                }, Colors.orange),
                _menuCard('Broadcast', Icons.campaign_rounded, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminAnnouncementScreen()));
                }, Colors.pinkAccent),
                _menuCard('Dispute Center', Icons.gavel_rounded, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDisputeListScreen()));
                }, Colors.redAccent),
                _menuCard('Helpdesk', Icons.headset_mic_rounded, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminSupportScreen()));
                }, Colors.cyanAccent),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5));
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }

  Widget _miniStatus(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: const TextStyle(color: Colors.white24, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _menuCard(String title, IconData icon, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
