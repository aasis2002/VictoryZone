import 'package:flutter/material.dart';
import '../../models/wallet_request_model.dart';
import '../../services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminDepositScreen extends StatelessWidget {
  const AdminDepositScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text('Verify Deposits')),
      body: StreamBuilder<List<WalletRequestModel>>(
        stream: firestore.getAllWalletRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No pending deposits', style: TextStyle(color: Colors.white24)));
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
                        Text('Rs. ${req.amount.toInt()}', 
                             style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF))),
                        _buildStatusBadge(req.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Ref ID: ${req.esewaRefId}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 16),
                    if (req.screenshotUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: GestureDetector(
                          onTap: () => _showImagePreview(context, req.screenshotUrl!),
                          child: CachedNetworkImage(
                            imageUrl: req.screenshotUrl!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                        ),
                      ),
                    if (req.status == 'pending') ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
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
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent[700]),
                              child: const Text('Approve'),
                            ),
                          ),
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

  void _updateStatus(BuildContext context, WalletRequestModel req, String status) async {
    await FirestoreService().updateWalletRequestStatus(
      requestId: req.requestId,
      newStatus: status,
      userId: req.userId,
      amount: req.amount,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Deposit $status')));
  }

  void _showImagePreview(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(16), child: CachedNetworkImage(imageUrl: url)),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orangeAccent;
    if (status == 'approved') color = Colors.greenAccent;
    if (status == 'rejected') color = Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}
