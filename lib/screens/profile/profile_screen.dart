import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';

import 'support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pubgController = TextEditingController();
  final _ffController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).userModel;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phoneNumber ?? '';
      _pubgController.text = user.pubgId ?? '';
      _ffController.text = user.freefireId ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.userModel;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)));
    }

    if (user.isSuspended) {
      return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.block_rounded, size: 80, color: Colors.redAccent),
              ),
              const SizedBox(height: 32),
              const Text('ACCOUNT SUSPENDED', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
              const SizedBox(height: 12),
              const Text('Your access has been revoked for violation of fair play terms.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, height: 1.5)),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => auth.signOut(),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                child: const Text('LOGOUT'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('SOLDIER PROFILE'),
        actions: [
          IconButton(
            onPressed: () => auth.signOut(),
            icon: const Icon(Icons.power_settings_new_rounded, color: Colors.redAccent),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            _buildProfileHeader(user),
            const SizedBox(height: 40),
            
            _sectionTitle('BATTLE STATISTICS'),
            const SizedBox(height: 16),
            Row(
              children: [
                _statItem('MISSIONS', user.totalMatches.toString()),
                _statItem('VICTORIES', user.totalWins.toString()),
                _statItem('FRAGS', user.totalKills.toString()),
              ],
            ),
            const SizedBox(height: 40),

            _sectionTitle('IDENTITY DETAILS'),
            const SizedBox(height: 16),
            _buildTextField(_nameController, 'FULL NAME', Icons.person_outline_rounded),
            const SizedBox(height: 16),
            _buildTextField(_phoneController, 'CONTACT NUMBER', Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildTextField(TextEditingController(text: user.email), 'EMAIL ADDRESS', Icons.email_outlined, enabled: false),
            
            const SizedBox(height: 32),
            _sectionTitle('GAMING PROTOCOLS'),
            const SizedBox(height: 16),
            _buildTextField(_pubgController, 'PUBG MOBILE ID', Icons.sports_esports_rounded),
            const SizedBox(height: 16),
            _buildTextField(_ffController, 'FREE FIRE ID', Icons.local_fire_department_rounded),
            
            const SizedBox(height: 32),
            _sectionTitle('HELP & LEGAL'),
            const SizedBox(height: 16),
            _buildMenuTile('SUPPORT CENTER', Icons.headset_mic_rounded, () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
            }),
            _buildMenuTile('TERMS & CONDITIONS', Icons.description_rounded, () {
              // Placeholder for legal
            }),

            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await auth.updateProfile(
                    name: _nameController.text.trim(), 
                    phoneNumber: _phoneController.text.trim(),
                    pubgId: _pubgController.text.trim(),
                    freefireId: _ffController.text.trim(),
                    photoUrl: user.photoUrl
                  );
                  messenger.showSnackBar(const SnackBar(content: Text('PROFILE UPDATED SUCCESSFULLY'), backgroundColor: Colors.green));
                } catch (e) {
                  messenger.showSnackBar(SnackBar(content: Text(e.toString().toUpperCase()), backgroundColor: Colors.redAccent));
                }
              },
              child: const Text('SAVE CHANGES'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: AppTheme.backgroundColor,
                backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                child: user.photoUrl == null 
                    ? const Icon(Icons.person_rounded, size: 60, color: Colors.white12) 
                    : null,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(color: AppTheme.accentColor, shape: BoxShape.circle),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.black, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(user.name.toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
            if (user.isVerified) ...[
              const SizedBox(width: 8),
              const Icon(Icons.verified_rounded, color: AppTheme.accentColor, size: 22),
            ],
          ],
        ),
        Text(user.role.toUpperCase(), style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 11)),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 4),
        child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentColor, letterSpacing: 1.5)),
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(String title, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.03)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.accentColor, size: 20),
        title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        trailing: const Icon(Icons.chevron_right, color: Colors.white10, size: 18),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool enabled = true, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      style: TextStyle(color: enabled ? Colors.white : Colors.white54, fontWeight: FontWeight.w600, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      ),
    );
  }
}
