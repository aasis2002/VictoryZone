import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/notification_service.dart';
import '../../services/firestore_service.dart';
import '../../models/tournament_model.dart';
import '../../core/constants.dart';

class AdminAnnouncementScreen extends StatefulWidget {
  const AdminAnnouncementScreen({super.key});

  @override
  State<AdminAnnouncementScreen> createState() => _AdminAnnouncementScreenState();
}

class _AdminAnnouncementScreenState extends State<AdminAnnouncementScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSending = false;
  String _targetType = 'All Users';
  String? _selectedTournamentId;
  List<TournamentModel> _tournaments = [];

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  void _loadTournaments() async {
    FirestoreService().getAllTournaments().listen((list) {
      if (mounted) setState(() => _tournaments = list);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text('Broadcast Center')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Recipient Group'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _targetType,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  items: ['All Users', 'Specific Tournament Participants'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => _targetType = v!),
                ),
              ),
            ),

            if (_targetType != 'All Users') ...[
              const SizedBox(height: 24),
              _label('Select Tournament'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedTournamentId,
                    hint: const Text('Select a match...', style: TextStyle(color: Colors.white24)),
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    items: _tournaments.map((t) => DropdownMenuItem(value: t.id, child: Text(t.title))).toList(),
                    onChanged: (v) => setState(() => _selectedTournamentId = v),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
            _label('Notification Content'),
            _buildTextField(_titleController, 'Title (e.g., Match Delayed)', Icons.title_rounded),
            const SizedBox(height: 16),
            _buildTextField(_bodyController, 'Message Body', Icons.description_rounded, maxLines: 4),
            const SizedBox(height: 48),
            _isSending 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _handleSend,
                  icon: const Icon(Icons.send_rounded),
                  label: Text('BROADCAST TO ${_targetType.toUpperCase()}'),
                ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(text, style: const TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  void _handleSend() async {
    if (_titleController.text.isEmpty || _bodyController.text.isEmpty) return;
    if (_targetType != 'All Users' && _selectedTournamentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a tournament.')));
      return;
    }

    setState(() => _isSending = true);
    try {
      if (_targetType == 'All Users') {
        final usersSnapshot = await FirebaseFirestore.instance.collection(AppConstants.usersColl).get();
        for (var doc in usersSnapshot.docs) {
          await NotificationService.sendAndLogNotification(
            userId: doc.id,
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            type: 'general',
          );
        }
      } else {
        await FirestoreService().notifyTournamentPlayers(
          tournamentId: _selectedTournamentId!,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          type: 'tournament',
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast sent successfully!'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
}
