import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/tournament_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../core/theme.dart';
import '../home/dispute_report_screen.dart';

class TournamentDetailScreen extends StatefulWidget {
  final TournamentModel tournament;
  const TournamentDetailScreen({super.key, required this.tournament});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  late Timer _timer;
  Duration _timeUntilStart = const Duration();

  @override
  void initState() {
    super.initState();
    _calculateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) _calculateTimeRemaining();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _calculateTimeRemaining() {
    try {
      final now = DateTime.now();
      final matchDate = DateTime.parse('${widget.tournament.date} ${widget.tournament.time}');
      final diff = matchDate.difference(now);
      setState(() => _timeUntilStart = diff.isNegative ? Duration.zero : diff);
    } catch (e) {
      // Handle date parsing error
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final firestore = FirestoreService();
    
    final bool showLeaderboard = widget.tournament.status == 'live' || 
                                widget.tournament.status == 'results_pending' || 
                                widget.tournament.status == 'completed';

    return DefaultTabController(
      length: showLeaderboard ? 3 : 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              stretch: true,
              backgroundColor: AppTheme.backgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(widget.tournament.imageUrl, fit: BoxFit.cover),
                    Container(decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.backgroundColor, Colors.transparent],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        stops: const [0.1, 0.8],
                      )
                    )),
                    Positioned(
                      bottom: 40,
                      left: 24,
                      right: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _statusBadge(widget.tournament.status),
                          const SizedBox(height: 12),
                          Text(widget.tournament.title.toUpperCase(), 
                               style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _infoBadge(widget.tournament.gameType, AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              _infoBadge(widget.tournament.gameMode, Colors.white12),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottom: TabBar(
                tabs: [
                  const Tab(text: 'OVERVIEW'),
                  const Tab(text: 'RULES'),
                  if (showLeaderboard)
                    Tab(text: widget.tournament.status == 'completed' ? 'RANKINGS' : 'INTEL'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _buildOverview(context, auth),
              _buildRules(),
              if (showLeaderboard)
                _buildLeaderboard(context, auth),
            ],
          ),
        ),
        bottomNavigationBar: (widget.tournament.status == 'published') 
          ? _buildBottomBar(context, auth, firestore) 
          : null,
      ),
    );
  }

  Widget _buildOverview(BuildContext context, AuthProvider auth) {
    final String countdown = "${_timeUntilStart.inDays}D ${_timeUntilStart.inHours % 24}H ${_timeUntilStart.inMinutes % 60}M ${_timeUntilStart.inSeconds % 60}S";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_timeUntilStart.inSeconds > 0) ...[
            _sectionTitle('DEPLOYMENT COUNTDOWN'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF6E00FF).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Text(countdown, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 2)),
            ),
            const SizedBox(height: 32),
          ],
          _sectionTitle('MISSION LOGISTICS'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _matchInfoItem(Icons.calendar_today_rounded, 'DATE', widget.tournament.date),
                _matchInfoItem(Icons.access_time_rounded, 'TIME', widget.tournament.time),
                _matchInfoItem(Icons.map_rounded, 'MAP', widget.tournament.map ?? 'TBA'),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _sectionTitle('BOUNTY CONTRACTS'),
          const SizedBox(height: 16),
          _prizeItem('1ST PLACE', 'Rs. ${widget.tournament.firstPrize.toInt()}', Icons.emoji_events_rounded, Colors.amberAccent),
          _prizeItem('2ND PLACE', 'Rs. ${widget.tournament.secondPrize.toInt()}', Icons.emoji_events_rounded, const Color(0xFF94A3B8)),
          _prizeItem('3RD PLACE', 'Rs. ${widget.tournament.thirdPrize.toInt()}', Icons.emoji_events_rounded, Colors.orangeAccent),
          _prizeItem('PER FRAG', 'Rs. ${widget.tournament.killReward.toInt()}', Icons.military_tech_rounded, Colors.redAccent),
          const SizedBox(height: 32),
          _sectionTitle('BRIEFING'),
          const SizedBox(height: 12),
          Text(widget.tournament.description ?? 'No specific mission briefing available.', 
               style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.6)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(BuildContext context, AuthProvider auth) {
    return StreamBuilder<List<TournamentEntry>>(
      stream: FirestoreService().getTournamentEntries(widget.tournament.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final entries = snapshot.data!;
        if (entries.isEmpty) return const Center(child: Text('WAITING FOR INTEL...', style: TextStyle(color: Colors.white12, letterSpacing: 2)));

        entries.sort((a, b) {
          int rankA = a.rank ?? 999;
          int rankB = b.rank ?? 999;
          if (rankA == 0) rankA = 999;
          if (rankB == 0) rankB = 999;
          return rankA.compareTo(rankB);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: entries.length,
          itemBuilder: (ctx, index) {
            final entry = entries[index];
            final bool hasRank = (entry.rank ?? 0) > 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: (hasRank && entry.rank! <= 3) ? AppTheme.primaryColor.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(hasRank ? '#${entry.rank}' : '•', 
                         style: TextStyle(
                           color: entry.rank == 1 ? Colors.amberAccent : (entry.rank == 2 ? Colors.blueGrey[200] : (entry.rank == 3 ? Colors.orangeAccent : Colors.white24)),
                           fontWeight: FontWeight.bold, fontSize: 20
                         )),
                  ),
                  const CircleAvatar(radius: 18, backgroundColor: Colors.black26, child: Icon(Icons.person, size: 20, color: Colors.white38)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PLAYER ${entry.userId.substring(0, 5).toUpperCase()}', 
                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        if (auth.userModel?.uid != entry.userId)
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DisputeReportScreen(
                              tournamentId: widget.tournament.id,
                              reporterId: auth.userModel!.uid,
                              reportedUserId: entry.userId,
                              reportedUserName: 'Player ${entry.userId.substring(0, 5)}',
                            ))),
                            child: const Text('REPORT PLAYER', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                          ),
                      ],
                    ),
                  ),
                  if (hasRank)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${entry.totalPoints?.toInt()} PTS', style: const TextStyle(color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
                        Text('${entry.kills} KILLS', style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    )
                  else
                    const Text('READY', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRules() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.cardColor, 
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Text(widget.tournament.rules ?? 'Standard engagement rules apply.', 
                   style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.8, letterSpacing: 0.2)),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, AuthProvider auth, FirestoreService firestore) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF161E31),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ENTRY COST', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(widget.tournament.entryFee == 0 ? 'FREE ENTRY' : 'RS. ${widget.tournament.entryFee.toInt()}', 
                     style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _handleJoin(context, auth, firestore),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(160, 56),
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('ENLIST NOW'),
          ),
        ],
      ),
    );
  }

  void _handleJoin(BuildContext context, AuthProvider auth, FirestoreService firestore) async {
    if (auth.userModel == null) return;
    if (auth.userModel!.walletBalance < widget.tournament.entryFee) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('INSUFFICIENT FUNDS. TOP UP TO JOIN.')));
      return;
    }
    try {
      await firestore.joinTournament(widget.tournament.id, auth.userModel!.uid, widget.tournament.entryFee);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('DEPLOYMENT SUCCESSFUL!'), backgroundColor: Colors.green));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().toUpperCase())));
    }
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.accentColor, letterSpacing: 2));
  }

  Widget _infoBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(text.toUpperCase(), style: TextStyle(color: color == Colors.white12 ? Colors.white70 : color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }

  Widget _matchInfoItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accentColor, size: 20),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _prizeItem(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
          const Spacer(),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.blueAccent;
    if (status == 'live') color = Colors.redAccent;
    if (status == 'results_pending') color = Colors.orangeAccent;
    if (status == 'completed') color = Colors.greenAccent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == 'live') Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 6), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
          Text(status.toUpperCase().replaceAll('_', ' '), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}
