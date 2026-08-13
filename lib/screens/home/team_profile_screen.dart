import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/team_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/team_provider.dart';
import '../../services/firestore_service.dart';
import 'invite_player_screen.dart';

class TeamProfileScreen extends StatelessWidget {
  final String teamId;
  const TeamProfileScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    final auth = Provider.of<AuthProvider>(context);
    final teamProvider = Provider.of<TeamProvider>(context);

    return StreamBuilder<TeamModel?>(
      stream: firestore.getTeamStream(teamId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final team = snapshot.data;
        if (team == null) return const Scaffold(body: Center(child: Text('Team not found')));

        final isLeader = team.leaderId == auth.userModel?.uid;

        return Scaffold(
          appBar: AppBar(
            title: Text(team.name),
            actions: [
              if (isLeader)
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  onPressed: () => _showEditTeamDialog(context, team, teamProvider),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFF1E293B),
                        backgroundImage: team.logoUrl != null ? NetworkImage(team.logoUrl!) : null,
                        child: team.logoUrl == null ? const Icon(Icons.group, size: 50, color: Colors.white24) : null,
                      ),
                      const SizedBox(height: 16),
                      Text(team.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(team.gameType, style: const TextStyle(color: Color(0xFF6E00FF), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 48),
                _sectionTitle('Members (${team.memberIds.length})'),
                const SizedBox(height: 16),
                FutureBuilder<List<UserModel>>(
                  future: firestore.getTeamMembers(team.memberIds),
                  builder: (context, memSnapshot) {
                    if (!memSnapshot.hasData) return const CircularProgressIndicator();
                    final members = memSnapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final isMemberLeader = team.leaderId == member.uid;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.white10,
                              backgroundImage: member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
                              child: member.photoUrl == null ? const Icon(Icons.person, color: Colors.white24) : null,
                            ),
                            title: Text(member.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text(isMemberLeader ? 'Captain' : 'Member', style: TextStyle(color: isMemberLeader ? const Color(0xFF00E5FF) : Colors.white54, fontSize: 12)),
                            trailing: isLeader && !isMemberLeader ? PopupMenuButton(
                              icon: const Icon(Icons.more_vert, color: Colors.white54),
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(value: 'remove', child: Text('Remove Member')),
                                const PopupMenuItem(value: 'transfer', child: Text('Make Captain')),
                              ],
                              onSelected: (val) {
                                if (val == 'remove') teamProvider.removeMember(teamId, member.uid);
                                if (val == 'transfer') teamProvider.transferCaptain(teamId, member.uid);
                              },
                            ) : null,
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),
                if (isLeader)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => InvitePlayerScreen(team: team)));
                    },
                    icon: const Icon(Icons.person_add_rounded),
                    label: const Text('Invite Players'),
                  ),
                const SizedBox(height: 16),
                if (!isLeader)
                  OutlinedButton.icon(
                    onPressed: () async {
                      await teamProvider.leaveTeam(teamId, auth.userModel!.uid);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                    label: const Text('Leave Team', style: TextStyle(color: Colors.redAccent)),
                    style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white));
  }

  void _showEditTeamDialog(BuildContext context, TeamModel team, TeamProvider provider) {
    final nameController = TextEditingController(text: team.name);
    final logoController = TextEditingController(text: team.logoUrl);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 32, left: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Edit Team', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 32),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Team Name', prefixIcon: Icon(Icons.group_rounded, color: Colors.white54)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: logoController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: 'Logo URL', prefixIcon: Icon(Icons.image_rounded, color: Colors.white54)),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () async {
                await provider.updateTeam(team.id, nameController.text.trim(), logoController.text.trim());
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              }, 
              child: const Text('Save Changes'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
