import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/team_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/team_model.dart';
import 'team_profile_screen.dart';

class MyTeamsScreen extends StatelessWidget {
  const MyTeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final teamProvider = Provider.of<TeamProvider>(context);
    final firestore = FirestoreService();

    if (auth.userModel == null) return const Scaffold();

    return Scaffold(
      appBar: AppBar(title: const Text('My Teams')),
      body: StreamBuilder<List<TeamModel>>(
        stream: firestore.getUserTeams(auth.userModel!.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_off_rounded, size: 80, color: Colors.white10),
                  const SizedBox(height: 16),
                  const Text('No teams created yet', style: TextStyle(color: Colors.white24)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _showCreateTeamDialog(context, auth.userModel!.uid, teamProvider),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                    child: const Text('Create New Team'),
                  ),
                ],
              ),
            );
          }

          final list = snapshot.data!;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: Responsive.isMobile(context) ? 1 : (Responsive.isTablet(context) ? 2 : 3),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 140,
                ),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final team = list[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TeamProfileScreen(teamId: team.id)));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: const Color(0xFF6E00FF).withValues(alpha: 0.1),
                                backgroundImage: team.logoUrl != null ? NetworkImage(team.logoUrl!) : null,
                                child: team.logoUrl == null ? const Icon(Icons.group, color: Color(0xFF6E00FF)) : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(team.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                                    Text(team.gameType, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('${team.memberIds.length} Members', style: const TextStyle(color: Colors.white54, fontSize: 13)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTeamDialog(context, auth.userModel!.uid, teamProvider),
        backgroundColor: const Color(0xFF6E00FF),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _showCreateTeamDialog(BuildContext context, String uid, TeamProvider provider) {
    final nameController = TextEditingController();
    String selectedGame = 'PUBG Mobile';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 32, left: 24, right: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Create Your Team', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 32),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(hintText: 'Team Name', prefixIcon: Icon(Icons.group_rounded, color: Colors.white54)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedGame,
                dropdownColor: const Color(0xFF1E293B),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.sports_esports_rounded, color: Colors.white54)),
                items: ['PUBG Mobile', 'Free Fire', 'Valorant'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setState(() => selectedGame = v!),
              ),
              const SizedBox(height: 48),
              provider.isLoading 
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) return;
                      await provider.createTeam(nameController.text.trim(), uid, selectedGame);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                    }, 
                    child: const Text('Create Team'),
                  ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
