import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../models/dispute_model.dart';
import '../../services/firestore_service.dart';

class DisputeReportScreen extends StatefulWidget {
  final String tournamentId;
  final String reporterId;
  final String reportedUserId;
  final String reportedUserName;

  const DisputeReportScreen({
    super.key,
    required this.tournamentId,
    required this.reporterId,
    required this.reportedUserId,
    required this.reportedUserName,
  });

  @override
  State<DisputeReportScreen> createState() => _DisputeReportScreenState();
}

class _DisputeReportScreenState extends State<DisputeReportScreen> {
  final _descController = TextEditingController();
  String _selectedReason = 'Hacking/Cheat Software';
  File? _evidenceImage;
  bool _isSubmitting = false;

  final List<String> _reasons = [
    'Hacking/Cheat Software',
    'Teaming with Enemies',
    'Toxic/Abusive Behavior',
    'Fake Result Screenshot',
    'Other',
  ];

  Future<void> _pickEvidence() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _evidenceImage = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text('Report Fair Play Violation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reporting: ${widget.reportedUserName}', 
                 style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Provide clear evidence to help admins investigate.', 
                       style: TextStyle(color: Colors.white54, fontSize: 13)),
            
            const SizedBox(height: 32),
            _label('Reason for Report'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedReason,
                  isExpanded: true,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  items: _reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setState(() => _selectedReason = v!),
                ),
              ),
            ),

            const SizedBox(height: 24),
            _label('Description'),
            TextField(
              controller: _descController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                hintText: 'Describe exactly what happened...',
                hintStyle: const TextStyle(color: Colors.white24),
              ),
            ),

            const SizedBox(height: 24),
            _label('Evidence (Screenshot/Proof)'),
            GestureDetector(
              onTap: _pickEvidence,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: _evidenceImage == null 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, color: Colors.white24, size: 40),
                        SizedBox(height: 8),
                        Text('Tap to upload image', style: TextStyle(color: Colors.white24)),
                      ],
                    )
                  : ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_evidenceImage!, fit: BoxFit.cover)),
              ),
            ),

            const SizedBox(height: 48),
            _isSubmitting 
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _submitReport,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                  child: const Text('SUBMIT REPORT'),
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

  void _submitReport() async {
    if (_descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please provide a description.')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String? url;
      if (_evidenceImage != null) {
        final ref = FirebaseStorage.instance.ref()
            .child('disputes')
            .child('${const Uuid().v4()}.jpg');
        await ref.putFile(_evidenceImage!);
        url = await ref.getDownloadURL();
      }

      final dispute = DisputeModel(
        id: const Uuid().v4(),
        tournamentId: widget.tournamentId,
        reporterId: widget.reporterId,
        reportedUserId: widget.reportedUserId,
        reason: _selectedReason,
        description: _descController.text.trim(),
        evidenceUrl: url,
        status: 'pending',
        timestamp: Timestamp.now(),
      );

      await FirestoreService().submitDispute(dispute);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted. Admins will investigate.'), backgroundColor: Colors.green));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
