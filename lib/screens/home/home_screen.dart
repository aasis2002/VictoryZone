import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/tournament_model.dart';
import '../../core/theme.dart';
import '../tournament/tournament_detail_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/profile_screen.dart';
import '../my_tournaments/my_tournaments_screen.dart';
import 'dashboard_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final List<Widget> _pages = const [
    DashboardScreen(),
    TournamentListPage(),
    MyTournamentsScreen(),
    WalletScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);

    return Scaffold(
      body: IndexedStack(
        index: navProvider.currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navProvider.currentIndex,
        onDestinationSelected: (index) => navProvider.setIndex(index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_rounded),
            label: 'Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.flash_on_rounded),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class TournamentListPage extends StatefulWidget {
  const TournamentListPage({super.key});

  @override
  State<TournamentListPage> createState() => _TournamentListPageState();
}

class _TournamentListPageState extends State<TournamentListPage> with SingleTickerProviderStateMixin {
  String selectedGame = 'All';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final tProvider = Provider.of<TournamentProvider>(context);
    final firestore = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('TOURNAMENTS'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'UPCOMING'),
            Tab(text: 'LIVE'),
            Tab(text: 'COMPLETED'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: TextField(
              onChanged: (v) => tProvider.setSearchQuery(v),
              decoration: const InputDecoration(
                hintText: 'Find your next battle...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: ['All', 'PUBG Mobile', 'Free Fire', 'Valorant'].map((game) {
                final isSelected = selectedGame == game;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: FilterChip(
                    label: Text(game),
                    selected: isSelected,
                    onSelected: (val) => setState(() => selectedGame = game),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTournamentList(firestore, 'published'),
                _buildTournamentList(firestore, 'live'),
                _buildTournamentList(firestore, 'completed', secondaryStatus: 'results_pending'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentList(FirestoreService firestore, String status, {String? secondaryStatus}) {
    return StreamBuilder<List<TournamentModel>>(
      stream: FirebaseFirestore.instance
          .collection('tournaments')
          .where('status', whereIn: secondaryStatus != null ? [status, secondaryStatus] : [status])
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => TournamentModel.fromMap(doc.id, doc.data())).toList()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_esports_outlined, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                const SizedBox(height: 16),
                Text('No $status tournaments found', style: const TextStyle(color: Colors.white24)),
              ],
            ),
          );
        }

        var list = snapshot.data!;
        if (selectedGame != 'All') {
          list = list.where((t) => t.gameType == selectedGame).toList();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (context, index) {
            return TournamentCard(tournament: list[index]);
          },
        );
      },
    );
  }
}

class TournamentCard extends StatelessWidget {
  final TournamentModel tournament;
  const TournamentCard({super.key, required this.tournament});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TournamentDetailScreen(tournament: tournament),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: tournament.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tournament.isFree ? 'FREE' : 'RS. ${tournament.entryFee.toInt()}',
                        style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  if (tournament.status == 'live')
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: StreamBuilder<int>(
                      stream: firestore.getRegistrationCount(tournament.id),
                      builder: (context, snapshot) {
                        int count = snapshot.data ?? 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$count / ${tournament.slots} PLAYERS',
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tournament.title.toUpperCase(), 
                         style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _tag(Icons.sports_esports_rounded, tournament.gameType),
                        const SizedBox(width: 16),
                        _tag(Icons.map_rounded, tournament.map ?? 'TBA'),
                        const SizedBox(width: 16),
                        _tag(Icons.calendar_today_rounded, tournament.date),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.accentColor),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 11, color: Colors.white54, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
