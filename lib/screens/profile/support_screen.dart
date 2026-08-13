import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../models/support_ticket_model.dart';
import '../../services/firestore_service.dart';
import '../../core/theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final firestore = FirestoreService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text('SUPPORT CENTER')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<SupportTicketModel>>(
              stream: firestore.getUserSupportTickets(auth.userModel!.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final tickets = snapshot.data!;

                if (tickets.isEmpty) {
                  return _emptySupportState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: tickets.length,
                  itemBuilder: (ctx, index) {
                    final ticket = tickets[index];
                    return _buildTicketCard(ticket);
                  },
                );
              },
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildTicketCard(SupportTicketModel ticket) {
    Color statusColor = Colors.orangeAccent;
    if (ticket.status == 'resolved') statusColor = Colors.greenAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ticket.subject.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(ticket.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(ticket.message, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          if (ticket.adminReply != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(color: Colors.white10),
            ),
            const Text('ADMIN RESPONSE:', style: TextStyle(color: AppTheme.accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
            const SizedBox(height: 4),
            Text(ticket.adminReply!, style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _emptySupportState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.headset_mic_rounded, size: 64, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 16),
          const Text('NEED ASSISTANCE?', style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Color(0xFF1E293B), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: ElevatedButton(
        onPressed: _showTicketForm,
        child: const Text('CREATE NEW TICKET'),
      ),
    );
  }

  void _showTicketForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 32, left: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('NEW SUPPORT TICKET', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Describe your issue and we will get back to you.', style: TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 32),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(hintText: 'Subject'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Message'),
            ),
            const SizedBox(height: 32),
            _isSubmitting 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: () => _submitTicket(ctx),
                  child: const Text('SUBMIT TICKET'),
                ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _submitTicket(BuildContext ctx) async {
    if (_subjectController.text.isEmpty || _messageController.text.isEmpty) return;
    setState(() => _isSubmitting = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    final ticket = SupportTicketModel(
      id: const Uuid().v4(),
      userId: auth.userModel!.uid,
      userName: auth.userModel!.name,
      subject: _subjectController.text.trim(),
      message: _messageController.text.trim(),
      status: 'open',
      priority: 'medium',
      timestamp: Timestamp.now(),
    );

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(ctx);

    await FirestoreService().submitSupportTicket(ticket);
    setState(() => _isSubmitting = false);
    _subjectController.clear();
    _messageController.clear();
    
    navigator.pop();
    messenger.showSnackBar(const SnackBar(content: Text('TICKET CREATED SUCCESSFULLY!')));
  }
}
