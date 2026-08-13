import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/support_ticket_model.dart';
import '../../services/firestore_service.dart';
import '../../core/theme.dart';

class AdminSupportScreen extends StatelessWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text('HELPDESK')),
      body: StreamBuilder<List<SupportTicketModel>>(
        stream: firestore.getAllSupportTickets(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('NO PENDING TICKETS', style: TextStyle(color: Colors.white24)));
          }

          final list = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final ticket = list[index];
              return _SupportTicketCard(ticket: ticket);
            },
          );
        },
      ),
    );
  }
}

class _SupportTicketCard extends StatelessWidget {
  final SupportTicketModel ticket;
  const _SupportTicketCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: ticket.status == 'open' ? Colors.blueAccent.withValues(alpha: 0.2) : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusBadge(ticket.status),
              Text(DateFormat('dd MMM, hh:mm a').format(ticket.timestamp.toDate()), 
                   style: const TextStyle(color: Colors.white24, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 16),
          Text(ticket.subject.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text('BY: ${ticket.userName}', style: const TextStyle(color: AppTheme.accentColor, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(ticket.message, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 20),
          const Divider(color: Colors.white10),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _showReplyDialog(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, minimumSize: const Size(double.infinity, 45)),
            child: const Text('REPLY & RESOLVE'),
          )
        ],
      ),
    );
  }

  void _showReplyDialog(BuildContext context) {
    final replyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Resolve Ticket', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: replyController,
          maxLines: 4,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Enter your response...', hintStyle: TextStyle(color: Colors.white24)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              final nav = Navigator.of(ctx);
              await FirestoreService().updateSupportTicket(ticket.id, 'resolved', replyController.text);
              nav.pop();
            },
            child: const Text('SUBMIT & CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.blueAccent;
    if (status == 'resolved') color = Colors.greenAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }
}
