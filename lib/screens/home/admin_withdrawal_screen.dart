import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/withdrawal_model.dart';
import '../../services/firestore_service.dart';

class AdminWithdrawalScreen extends StatelessWidget {
  const AdminWithdrawalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text('Manage Payouts')),
      body: StreamBuilder<List<WithdrawalModel>>(
        stream: firestore.getAllWithdrawalRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No withdrawal requests', style: TextStyle(color: Colors.white24)));
          }

          final list = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final req = list[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Amount to Pay', style: TextStyle(color: Colors.white54, fontSize: 10)),
                            Text('Rs. ${req.amount.toInt()}', 
                                 style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
                          ],
                        ),
                        _buildStatusBadge(req.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _infoRow(Icons.account_circle_outlined, 'eSewa ID', req.esewaId),
                    _infoRow(Icons.calendar_today_rounded, 'Requested On', DateFormat('dd MMM, hh:mm a').format(req.timestamp.toDate())),
                    
                    if (req.status == 'pending' || req.status == 'approved') ...[
                      const Divider(height: 32, color: Colors.white10),
                      Row(
                        children: [
                          if (req.status == 'pending') ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _updateStatus(context, req, 'rejected'),
                                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                                child: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _updateStatus(context, req, 'approved'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
                                child: const Text('Approve'),
                              ),
                            ),
                          ],
                          if (req.status == 'approved') ...[
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _updateStatus(context, req, 'completed'),
                                icon: const Icon(Icons.check_circle_rounded),
                                label: const Text('Mark as Paid'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent[700]),
                              ),
                            ),
                          ],
                        ],
                      )
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _updateStatus(BuildContext context, WithdrawalModel req, String status) async {
    await FirestoreService().updateWithdrawalStatus(
      requestId: req.requestId,
      newStatus: status,
      userId: req.userId,
      amount: req.amount,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request $status'), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.white24),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: Colors.white38, fontSize: 12)),
          Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orangeAccent;
    if (status == 'completed') color = Colors.greenAccent;
    if (status == 'rejected') color = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
