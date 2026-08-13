import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/team_provider.dart';

class InvitePlayerScreen extends StatefulWidget {
  final TeamModel team;
  const InvitePlayerScreen({super.key, required this.team});

  @override
  State<InvitePlayerScreen> createState() => _InvitePlayerScreenState();
}

class _InvitePlayerScreenState extends State<InvitePlayerScreen> {
  final _searchController = TextEditingController();
  List<UserModel> _results = [];
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final teamProvider = Provider.of<TeamProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Invite Players')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF6E00FF)),
                  onPressed: () async {
                    setState(() => _isSearching = true);
                    final res = await teamProvider.searchPlayers(_searchController.text.trim());
                    setState(() {
                      _results = res.where((u) => u.uid != auth.userModel!.uid && !widget.team.memberIds.contains(u.uid)).toList();
                      _isSearching = false;
                    });
                  },
                ),
              ),
            ),
          ),
          Expanded(
            child: _isSearching 
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty 
                  ? const Center(child: Text('No players found', style: TextStyle(color: Colors.white24)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: _results.length,
                      itemBuilder: (ctx, index) {
                        final user = _results[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.white10,
                              backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                              child: user.photoUrl == null ? const Icon(Icons.person, color: Colors.white24) : null,
                            ),
                            title: Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            trailing: ElevatedButton(
                              onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              await teamProvider.invitePlayer(
                                teamId: widget.team.id,
                                teamName: widget.team.name,
                                senderId: auth.userModel!.uid,
                                senderName: auth.userModel!.name,
                                receiverId: user.uid,
                              );
                              messenger.showSnackBar(
                                SnackBar(content: Text('Invitation sent to ${user.name}')),
                              );
                            },
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(80, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: const Text('Invite', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
