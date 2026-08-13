import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/tournament_model.dart';
import '../../services/firestore_service.dart';

class AdminTournamentScreen extends StatefulWidget {
  final TournamentModel? editTournament;
  const AdminTournamentScreen({super.key, this.editTournament});

  @override
  State<AdminTournamentScreen> createState() => _AdminTournamentScreenState();
}

class _AdminTournamentScreenState extends State<AdminTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _prizeController = TextEditingController();
  final _feeController = TextEditingController();
  final _slotsController = TextEditingController();
  final _maxTeamsController = TextEditingController();
  final _maxPlayersController = TextEditingController();
  final _imageController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _mapController = TextEditingController();
  final _versionController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rulesController = TextEditingController();

  final _regStartController = TextEditingController();
  final _regEndController = TextEditingController();
  final _matchDurationController = TextEditingController();
  final _roundsController = TextEditingController();

  // Prize Controllers
  final _totalPrizeController = TextEditingController();
  final _firstPrizeController = TextEditingController();
  final _secondPrizeController = TextEditingController();
  final _thirdPrizeController = TextEditingController();
  final _killRewardController = TextEditingController();
  final _mvpRewardController = TextEditingController();
  final _otherRewardsController = TextEditingController();

  String _selectedGame = 'PUBG Mobile';
  String _selectedMode = 'Solo';
  bool _isFree = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editTournament != null) {
      final t = widget.editTournament!;
      _titleController.text = t.title;
      _prizeController.text = t.prize;
      _feeController.text = t.entryFee.toString();
      _slotsController.text = t.slots.toString();
      _maxTeamsController.text = t.maxTeams.toString();
      _maxPlayersController.text = t.maxPlayers.toString();
      _imageController.text = t.imageUrl;
      _dateController.text = t.date;
      _timeController.text = t.time;
      _mapController.text = t.map ?? '';
      _versionController.text = t.version ?? '';
      _descriptionController.text = t.description ?? '';
      _rulesController.text = t.rules ?? '';
      _regStartController.text = t.registrationStart ?? '';
      _regEndController.text = t.registrationEnd ?? '';
      _matchDurationController.text = t.matchDuration ?? '';
      _roundsController.text = (t.numberOfRounds ?? 1).toString();
      _totalPrizeController.text = t.totalPrizePool.toString();
      _firstPrizeController.text = t.firstPrize.toString();
      _secondPrizeController.text = t.secondPrize.toString();
      _thirdPrizeController.text = t.thirdPrize.toString();
      _killRewardController.text = t.killReward.toString();
      _mvpRewardController.text = t.mvpReward.toString();
      _otherRewardsController.text = t.otherRewards ?? '';
      _selectedGame = t.gameType;
      _selectedMode = t.gameMode;
      _isFree = t.isFree;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: Text(widget.editTournament == null ? 'Create Tournament' : 'Edit Tournament')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              _buildTextField(_titleController, 'Tournament Name', Icons.title_rounded),
              const SizedBox(height: 16),
              _buildDropdown('Game', _selectedGame, ['PUBG Mobile', 'Free Fire', 'Valorant'], (v) => setState(() => _selectedGame = v!)),
              const SizedBox(height: 16),
              _buildDropdown('Game Mode', _selectedMode, ['Solo', 'Duo', 'Squad'], (v) => setState(() => _selectedMode = v!)),
              
              const SizedBox(height: 32),
              _buildSectionTitle('Registration Schedule'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_regStartController, 'Reg. Start (YYYY-MM-DD)', Icons.login_rounded)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_regEndController, 'Reg. End (YYYY-MM-DD)', Icons.logout_rounded)),
                ],
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('Tournament Schedule'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_dateController, 'Date (YYYY-MM-DD)', Icons.calendar_today_rounded)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_timeController, 'Start Time (HH:MM)', Icons.access_time_rounded)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_matchDurationController, 'Match Duration (e.g. 30 mins)', Icons.timer_rounded)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_roundsController, 'Total Rounds', Icons.reorder_rounded, keyboardType: TextInputType.number)),
                ],
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('Entry & Slots'),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Free Tournament', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                value: _isFree,
                onChanged: (v) => setState(() => _isFree = v),
                activeThumbColor: const Color(0xFF00E5FF),
                activeTrackColor: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                contentPadding: EdgeInsets.zero,
              ),
              if (!_isFree) ...[
                const SizedBox(height: 8),
                _buildTextField(_feeController, 'Entry Fee (Rs.)', Icons.payments_rounded, keyboardType: TextInputType.number),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_maxTeamsController, 'Max Teams', Icons.group_rounded, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_maxPlayersController, 'Max Players', Icons.person_rounded, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(_slotsController, 'Total Slot Capacity', Icons.format_list_numbered_rounded, keyboardType: TextInputType.number),

              const SizedBox(height: 32),
              _buildSectionTitle('Prize Distribution'),
              const SizedBox(height: 16),
              _buildTextField(_totalPrizeController, 'Total Prize Pool (Rs.)', Icons.account_balance_wallet_rounded, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_firstPrizeController, '1st Place', Icons.emoji_events_rounded, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_secondPrizeController, '2nd Place', Icons.emoji_events_rounded, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_thirdPrizeController, '3rd Place', Icons.emoji_events_rounded, keyboardType: TextInputType.number)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_killRewardController, 'Kill Reward', Icons.military_tech_rounded, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(_mvpRewardController, 'MVP Reward', Icons.star_rounded, keyboardType: TextInputType.number),
              const SizedBox(height: 16),
              _buildTextField(_otherRewardsController, 'Other Rewards', Icons.redeem_rounded, required: false),
              const SizedBox(height: 16),
              _buildTextField(_prizeController, 'Prize Summary (Text)', Icons.summarize_rounded),

              const SizedBox(height: 32),
              _buildSectionTitle('Game Details'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTextField(_mapController, 'Map Name', Icons.map_rounded)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField(_versionController, 'Game Version', Icons.layers_rounded)),
                ],
              ),

              const SizedBox(height: 32),
              _buildSectionTitle('Visuals & Content'),
              const SizedBox(height: 16),
              _buildTextField(_imageController, 'Banner Image URL', Icons.image_rounded, required: false),
              const SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Description', Icons.description_rounded, maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField(_rulesController, 'Rules (One per line)', Icons.gavel_rounded, maxLines: 5),

              const SizedBox(height: 48),
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: Color(0xFF6E00FF)))
              else
                ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6E00FF),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                  child: Text(widget.editTournament == null ? 'Publish Tournament' : 'Update Tournament', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields correctly')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final entryFee = _isFree ? 0.0 : (double.tryParse(_feeController.text.trim()) ?? 0.0);
      final totalSlots = int.tryParse(_slotsController.text.trim()) ?? 0;
      final maxTeams = int.tryParse(_maxTeamsController.text.trim()) ?? 0;
      final maxPlayers = int.tryParse(_maxPlayersController.text.trim()) ?? 0;
      final rounds = int.tryParse(_roundsController.text.trim()) ?? 1;

      final totalPrize = double.tryParse(_totalPrizeController.text.trim()) ?? 0.0;
      final firstPrize = double.tryParse(_firstPrizeController.text.trim()) ?? 0.0;
      final secondPrize = double.tryParse(_secondPrizeController.text.trim()) ?? 0.0;
      final thirdPrize = double.tryParse(_thirdPrizeController.text.trim()) ?? 0.0;
      final killReward = double.tryParse(_killRewardController.text.trim()) ?? 0.0;
      final mvpReward = double.tryParse(_mvpRewardController.text.trim()) ?? 0.0;

      final tournament = TournamentModel(
        id: widget.editTournament?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        gameType: _selectedGame,
        gameMode: _selectedMode,
        date: _dateController.text.trim(),
        time: _timeController.text.trim(),
        entryFee: entryFee,
        isFree: _isFree,
        maxTeams: maxTeams,
        maxPlayers: maxPlayers,
        slots: totalSlots,
        prize: _prizeController.text.trim(),
        imageUrl: _imageController.text.trim().isEmpty 
            ? 'https://firebasestorage.googleapis.com/v0/b/victory-zone-app.appspot.com/o/default_banner.jpg?alt=media' 
            : _imageController.text.trim(),
        status: widget.editTournament?.status ?? 'published',
        map: _mapController.text.trim(),
        version: _versionController.text.trim(),
        description: _descriptionController.text.trim(),
        rules: _rulesController.text.trim(),
        registrationStart: _regStartController.text.trim(),
        registrationEnd: _regEndController.text.trim(),
        matchDuration: _matchDurationController.text.trim(),
        numberOfRounds: rounds,
        totalPrizePool: totalPrize,
        firstPrize: firstPrize,
        secondPrize: secondPrize,
        thirdPrize: thirdPrize,
        killReward: killReward,
        mvpReward: mvpReward,
        otherRewards: _otherRewardsController.text.trim(),
        placementPointsConfig: widget.editTournament?.placementPointsConfig ?? const {
          '1': 15, '2': 12, '3': 10, '4': 8, '5': 6, 
          '6': 4, '7': 2, '8': 1, '9': 1, '10': 1
        },
        pointsPerKill: widget.editTournament?.pointsPerKill ?? 1.0,
      );

      if (widget.editTournament == null) {
        await FirestoreService().createTournament(tournament);
      } else {
        await FirestoreService().updateTournament(tournament);
      }
      
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.editTournament == null ? 'Tournament Published!' : 'Tournament Updated!'), 
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'), 
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF00E5FF)));
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType, int maxLines = 1, bool required = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      validator: (v) {
        if (required && (v == null || v.isEmpty)) return 'This field is required';
        return null;
      },
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
      onChanged: onChanged,
    );
  }
}
