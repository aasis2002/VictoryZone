import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/tournament_model.dart';
import '../../services/firestore_service.dart';

class AdminRoomInfoScreen extends StatefulWidget {
  final TournamentModel tournament;
  const AdminRoomInfoScreen({super.key, required this.tournament});

  @override
  State<AdminRoomInfoScreen> createState() => _AdminRoomInfoScreenState();
}

class _AdminRoomInfoScreenState extends State<AdminRoomInfoScreen> {
  final _roomIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _matchNumController = TextEditingController();
  final _startTimeController = TextEditingController();
  bool _isReleased = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingInfo();
  }

  void _loadExistingInfo() async {
    final doc = await FirebaseFirestore.instance
        .collection('tournaments')
        .doc(widget.tournament.id)
        .collection('private')
        .doc('room_info')
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _roomIdController.text = data['roomId'] ?? '';
        _passwordController.text = data['roomPassword'] ?? '';
        _matchNumController.text = (data['matchNumber'] ?? '1').toString();
        _startTimeController.text = data['startTime'] ?? widget.tournament.time;
        _isReleased = data['isReleased'] ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text('Room Information')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('Access Credentials'),
            const SizedBox(height: 16),
            _buildTextField(_roomIdController, 'Room ID', Icons.vpn_key_rounded),
            const SizedBox(height: 16),
            _buildTextField(_passwordController, 'Room Password', Icons.lock_outline_rounded),
            
            const SizedBox(height: 32),
            _sectionTitle('Match Specifics'),
            const SizedBox(height: 16),
            _buildTextField(_matchNumController, 'Match Number', Icons.format_list_numbered_rounded),
            const SizedBox(height: 16),
            _buildTextField(_startTimeController, 'Actual Start Time', Icons.timer_rounded),

            const SizedBox(height: 32),
            SwitchListTile(
              title: const Text('Release to Players', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              subtitle: const Text('Once enabled, confirmed players can see these details.', style: TextStyle(color: Colors.white54, fontSize: 12)),
              value: _isReleased,
              onChanged: (v) => setState(() => _isReleased = v),
              activeThumbColor: const Color(0xFF00E5FF),
              activeTrackColor: const Color(0xFF00E5FF).withValues(alpha: 0.3),
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 48),
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _saveInfo,
                  child: const Text('UPDATE ROOM INFO'),
                ),
          ],
        ),
      ),
    );
  }

  void _saveInfo() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance
          .collection('tournaments')
          .doc(widget.tournament.id)
          .collection('private')
          .doc('room_info')
          .set({
        'roomId': _roomIdController.text.trim(),
        'roomPassword': _passwordController.text.trim(),
        'matchNumber': _matchNumController.text.trim(),
        'startTime': _startTimeController.text.trim(),
        'isReleased': _isReleased,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (_isReleased) {
        await FirestoreService().notifyTournamentPlayers(
          tournamentId: widget.tournament.id,
          title: 'Room Details Released!',
          body: 'Credentials for ${widget.tournament.title} are now available. Join now!',
          type: 'tournament',
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Room info updated successfully!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)));
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
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
}
