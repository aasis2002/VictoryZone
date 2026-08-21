import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
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
  final Set<String> _sentInvites = {};

  @override
  void initState() {
    super.initState();
    // Auto-populate with recommended players
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleSearch());
  }

  Future<void> _handleSearch() async {
    final teamProvider = Provider.of<TeamProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    setState(() => _isSearching = true);
    try {
      final res = await teamProvider.searchPlayers(_searchController.text.trim());
      setState(() {
        _results = res.where((u) => u.uid != auth.userModel!.uid && !widget.team.memberIds.contains(u.uid)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load players: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamProvider = Provider.of<TeamProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final isDesktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Invite Players')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 48.0 : 24.0,
                  vertical: 24.0,
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _handleSearch(),
                  decoration: InputDecoration(
                    hintText: 'Search by name...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Color(0xFF6E00FF)),
                      onPressed: _handleSearch,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isSearching 
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty 
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_search_rounded, size: 64, color: Colors.white10),
                              SizedBox(height: 16),
                              Text('No players found', style: TextStyle(color: Colors.white24, fontSize: 16, fontWeight: FontWeight.bold)),
                              SizedBox(height: 8),
                              Text('Try searching for a name to find players\nto invite to your team.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white10, fontSize: 12)),
                            ],
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: Responsive.isMobile(context) ? 1 : (Responsive.isTablet(context) ? 2 : 3),
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 95,
                          ),
                          itemCount: _results.length,
                          itemBuilder: (ctx, index) {
                            final user = _results[index];
                            final isInviteSent = _sentInvites.contains(user.uid);

                            return Container(
                              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                              child: Center(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.white10,
                                    backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                                    child: user.photoUrl == null ? const Icon(Icons.person, color: Colors.white24) : null,
                                  ),
                                  title: Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                                  trailing: ElevatedButton(
                                    onPressed: isInviteSent ? null : () async {
                                      setState(() => _sentInvites.add(user.uid));
                                      final messenger = ScaffoldMessenger.of(context);
                                      try {
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
                                      } catch (e) {
                                        setState(() => _sentInvites.remove(user.uid));
                                        messenger.showSnackBar(
                                          SnackBar(content: Text('Failed to invite: $e')),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isInviteSent ? Colors.white10 : const Color(0xFF6E00FF),
                                      minimumSize: const Size(80, 36),
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                    child: Text(isInviteSent ? 'Sent' : 'Invite', style: const TextStyle(fontSize: 12)),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
