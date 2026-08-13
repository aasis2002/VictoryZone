import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/tournament_model.dart';
import '../../models/match_model.dart';
import '../../core/theme.dart';
import '../tournament/tournament_detail_screen.dart';

class MyTournamentsScreen extends StatelessWidget {
  const MyTournamentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final navProvider = Provider.of<NavigationProvider>(context, listen: false);
    final firestore = FirestoreService();

    if (auth.userModel == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(
        title: const Text('BATTLE LOG'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: AppTheme.accentColor),
            onPressed: () => _showHelp(context),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestore.getJoinedEvents(auth.userModel!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), shape: BoxShape.circle),
                    child: Icon(Icons.sports_esports_rounded, size: 80, color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  const SizedBox(height: 24),
                  const Text("NO ACTIVE MISSIONS", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => navProvider.setIndex(1), // Go to Matches tab
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(220, 56),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('FIND MATCHES'),
                  ),
                ],
              ),
            );
          }

          final list = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              final TournamentModel t = item['tournament'];
              final entry = item['entry'];
              final status = entry['status'] ?? 'confirmed';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.all(20),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.flash_on_rounded, color: AppTheme.primaryColor, size: 24),
                      ),
                      title: Text(t.title.toUpperCase(), 
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, letterSpacing: 0.5)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text('${t.gameType} • ${t.date}', 
                               style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _buildStatusBadge(status),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white10),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournament: t)));
                      },
                    ),
                    
                    // assigned Group Intel
                    _buildAssignedGroupInfo(t.id, auth.userModel!.uid),
                    
                    _buildSecureRoomInfo(t.id, auth.userModel!.uid),

                    if (status == 'confirmed')
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: ElevatedButton.icon(
                          onPressed: () => _showSubmitDialog(context, auth.userModel!.uid, t.id),
                          icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                          label: const Text('SUBMIT MISSION PROOF'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            foregroundColor: Colors.white70,
                            minimumSize: const Size(double.infinity, 50),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildAssignedGroupInfo(String tournamentId, String uid) {
    return StreamBuilder<List<MatchModel>>(
      stream: FirestoreService().getTournamentMatches(tournamentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        
        // Find the match where the user is a participant
        MatchModel? myMatch;
        try {
          myMatch = snapshot.data!.lastWhere((m) => m.playerIds.contains(uid));
        } catch (e) {
          myMatch = null;
        }

        if (myMatch == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF6E00FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6E00FF).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.groups_rounded, size: 16, color: Color(0xFF6E00FF)),
                const SizedBox(width: 12),
                Text('ASSIGNED: ROUND ${myMatch.roundNumber} - ${myMatch.groupName}', 
                     style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSecureRoomInfo(String tournamentId, String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .doc(tournamentId)
          .collection('private')
          .doc('room_info')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(16)),
              child: const Row(
                children: [
                  Icon(Icons.lock_clock_rounded, size: 16, color: Colors.white12),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('INTEL PENDING RELEASE BY COMMAND', 
                         style: TextStyle(color: Colors.white12, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        
        return Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _infoColumn('ROOM ID', data['roomId'] ?? 'TBA'),
                  Container(width: 1, height: 30, color: Colors.white10),
                  _infoColumn('PASSWORD', data['roomPassword'] ?? 'TBA'),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_rounded, size: 12, color: AppTheme.accentColor),
                    const SizedBox(width: 8),
                    Text('MATCH #${data['matchNumber']} STARTS AT ${data['startTime']}', 
                         style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _infoColumn(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.white24, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.accentColor, letterSpacing: 1)),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.greenAccent;
    String text = status.toUpperCase();

    if (status == 'pending_verification') {
      color = Colors.orangeAccent;
      text = 'VERIFICATION PENDING';
    } else if (status == 'completed') {
      color = Colors.blueAccent;
      text = 'MISSION COMPLETE';
    } else if (status == 'refunded') {
      color = Colors.redAccent;
      text = 'FEES REFUNDED';
    } else if (status == 'disqualified') {
      color = Colors.red;
      text = 'DISQUALIFIED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  void _showSubmitDialog(BuildContext context, String uid, String tId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => ResultUploadSheet(uid: uid, tId: tId),
    );
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MISSION PROTOCOLS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
            const SizedBox(height: 24),
            _helpRow(Icons.check_circle_rounded, 'CONFIRMED', 'Deployment ready. Slot secured in the squad.'),
            _helpRow(Icons.vpn_key_rounded, 'ROOM INTEL', 'Lobby credentials will be released by command 15 minutes before start.'),
            _helpRow(Icons.cloud_upload_rounded, 'EVIDENCE', 'Post-mission, upload screenshot evidence of ranking and frags.'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _helpRow(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppTheme.accentColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.white38, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ResultUploadSheet extends StatefulWidget {
  final String uid;
  final String tId;
  const ResultUploadSheet({super.key, required this.uid, required this.tId});

  @override
  State<ResultUploadSheet> createState() => _ResultUploadSheetState();
}

class _ResultUploadSheetState extends State<ResultUploadSheet> {
  File? _image;
  final _killsController = TextEditingController();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _image = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 32, left: 24, right: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SUBMIT MISSION PROOF', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          const Text('Upload your end-of-match screenshot showing ranking and frags.', style: TextStyle(color: Colors.white38, fontSize: 13)),
          const SizedBox(height: 32),
          _label('SCREENSHOT EVIDENCE'),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: _image == null 
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.white24),
                      SizedBox(height: 12),
                      Text('TAP TO UPLOAD PROOF', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ],
                  )
                : ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.file(_image!, fit: BoxFit.cover)),
            ),
          ),
          const SizedBox(height: 24),
          _label('TOTAL FRAGS (KILLS)'),
          TextField(
            controller: _killsController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter total confirmed kills', prefixIcon: Icon(Icons.military_tech_rounded)),
          ),
          const SizedBox(height: 40),
          _isUploading 
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : ElevatedButton(
                onPressed: _submit, 
                child: const Text('SUBMIT DATA'),
              ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(text, style: const TextStyle(color: AppTheme.accentColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  Future<void> _submit() async {
    if (_image == null || _killsController.text.isEmpty) return;
    setState(() => _isUploading = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final ref = FirebaseStorage.instance.ref().child('results').child(widget.uid).child('${widget.tId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(_image!);
      final url = await ref.getDownloadURL();
      await FirestoreService().submitResult(userId: widget.uid, tournamentId: widget.tId, kills: _killsController.text.trim(), screenshotUrl: url);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('RESULT SUBMITTED. STANDBY FOR VERIFICATION.'), backgroundColor: Colors.green));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('ERROR: $e')));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }
}
