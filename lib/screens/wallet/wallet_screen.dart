import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/transaction_model.dart';
import '../../models/wallet_request_model.dart';
import '../../models/withdrawal_model.dart';
import '../../core/theme.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<WalletProvider>(context, listen: false).fetchConfig();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final wallet = Provider.of<WalletProvider>(context);
    final firestore = FirestoreService();
    final user = auth.userModel;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('VALOR BANK'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'LEDGER'),
              Tab(text: 'PENDING'),
            ],
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            if (user != null) _buildEnhancedBalanceCard(context, user, wallet),
            const SizedBox(height: 24),
            Expanded(
              child: TabBarView(
                children: [
                  _buildHistoryTab(auth, firestore),
                  _buildRequestsTab(auth, firestore),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedBalanceCard(BuildContext context, UserModel user, WalletProvider wallet) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          const Text('CURRENT BALANCE', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(
            'Rs. ${user.walletBalance.toInt()}',
            style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: -1),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                _miniStat('TOTAL WON', 'Rs. ${user.totalWon.toInt()}'),
                Container(width: 1, height: 30, color: Colors.white10),
                _miniStat('WITHDRAWN', 'Rs. ${user.totalWithdrawn.toInt()}'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showTopUpSheet(context, wallet, user.uid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryColor,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('ADD FUNDS', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showWithdrawSheet(context, wallet, user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black26,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('WITHDRAW', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(AuthProvider auth, FirestoreService firestore) {
    return StreamBuilder<List<TransactionModel>>(
      stream: firestore.getUserTransactions(auth.userModel!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _emptyState('NO TRANSACTION HISTORY', Icons.history_rounded);
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final tx = snapshot.data![index];
            final isCredit = tx.type == 'credit';
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _getTxColor(tx.description).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(_getTxIcon(tx.description), color: _getTxColor(tx.description), size: 20),
                ),
                title: Text(tx.description.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13, letterSpacing: 0.5)),
                subtitle: Text(DateFormat('dd MMM, hh:mm a').format(tx.timestamp.toDate()).toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                trailing: Text(
                  '${isCredit ? '+' : '-'} RS.${tx.amount.toInt()}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isCredit ? Colors.greenAccent : Colors.redAccent, letterSpacing: -0.5),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getTxColor(String desc) {
    if (desc.contains('Prize') || desc.contains('Bonus')) return Colors.amberAccent;
    if (desc.contains('Refund')) return Colors.greenAccent;
    if (desc.contains('Withdrawal')) return Colors.orangeAccent;
    return AppTheme.accentColor;
  }

  IconData _getTxIcon(String desc) {
    if (desc.contains('Prize')) return Icons.emoji_events_rounded;
    if (desc.contains('Bonus')) return Icons.redeem_rounded;
    if (desc.contains('Refund')) return Icons.settings_backup_restore_rounded;
    if (desc.contains('Withdrawal')) return Icons.outbound_rounded;
    if (desc.contains('Entry')) return Icons.sports_esports_rounded;
    return Icons.account_balance_wallet_rounded;
  }

  Widget _buildRequestsTab(AuthProvider auth, FirestoreService firestore) {
    return StreamBuilder<List<dynamic>>(
      stream: Rx.combineLatest2(
        firestore.getUserWalletRequests(auth.userModel!.uid),
        firestore.getUserWithdrawals(auth.userModel!.uid),
        (List<WalletRequestModel> d, List<WithdrawalModel> w) {
          final List<dynamic> combined = [...d, ...w];
          combined.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return combined;
        },
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _emptyState('NO PENDING REQUESTS', Icons.receipt_long_rounded);
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final item = snapshot.data![index];
            final isDeposit = item is WalletRequestModel;
            final amount = item.amount;
            final status = item.status;
            final type = isDeposit ? 'DEPOSIT' : 'WITHDRAWAL';

            Color statusColor = Colors.orangeAccent;
            if (status == 'approved' || status == 'completed') statusColor = Colors.greenAccent;
            if (status == 'rejected') statusColor = Colors.redAccent;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: (isDeposit ? Colors.greenAccent : Colors.orangeAccent).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isDeposit ? Colors.greenAccent : Colors.orangeAccent, size: 20),
                ),
                title: Text('$type: RS.${amount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14, letterSpacing: 0.5)),
                subtitle: Text('${DateFormat('dd MMM').format(item.timestamp.toDate()).toUpperCase()} • ID: ${item.requestId.substring(0, 8).toUpperCase()}', 
                               style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: statusColor.withValues(alpha: 0.2))),
                  child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _emptyState(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 20),
          Text(text, style: const TextStyle(color: Colors.white12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  void _showTopUpSheet(BuildContext context, WalletProvider wallet, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => TopUpBottomSheet(uid: uid, wallet: wallet),
    );
  }

  void _showWithdrawSheet(BuildContext context, WalletProvider wallet, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.backgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (ctx) => WithdrawBottomSheet(user: user),
    );
  }
}

class WithdrawBottomSheet extends StatefulWidget {
  final UserModel user;
  const WithdrawBottomSheet({super.key, required this.user});

  @override
  State<WithdrawBottomSheet> createState() => _WithdrawBottomSheetState();
}

class _WithdrawBottomSheetState extends State<WithdrawBottomSheet> {
  final _amountController = TextEditingController();
  late final TextEditingController _esewaController;

  @override
  void initState() {
    super.initState();
    _esewaController = TextEditingController(text: widget.user.phoneNumber ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (ctx, wallet, _) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, top: 32, left: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('WITHDRAW WINNINGS', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
            const SizedBox(height: 8),
            const Text('Funds will be transferred to your linked eSewa account.', style: TextStyle(color: Colors.white38, fontSize: 13)),
            const SizedBox(height: 32),
            _label('ESEWA ID / PHONE'),
            TextField(
              controller: _esewaController,
              decoration: const InputDecoration(hintText: 'e.g. 98XXXXXXXX', prefixIcon: Icon(Icons.account_circle_outlined)),
            ),
            const SizedBox(height: 20),
            _label('WITHDRAWAL AMOUNT'),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Amount in Rs.', prefixIcon: Icon(Icons.currency_rupee)),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text('AVAILABLE: RS. ${widget.user.walletBalance.toInt()}', style: const TextStyle(color: AppTheme.accentColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 40),
            if (wallet.isLoading)
              const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            else
              ElevatedButton(
                onPressed: () async {
                  final amountText = _amountController.text.trim();
                  final esewaId = _esewaController.text.trim();
                  if (amountText.isEmpty || esewaId.isEmpty) return;
                  final amount = double.tryParse(amountText) ?? 0;
                  if (amount < 100) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('MINIMUM WITHDRAWAL IS RS. 100')));
                    return;
                  }
                  if (amount > widget.user.walletBalance) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('INSUFFICIENT BALANCE')));
                    return;
                  }
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  try {
                    await wallet.requestWithdrawal(widget.user.uid, amount, esewaId);
                    navigator.pop();
                    messenger.showSnackBar(const SnackBar(content: Text('WITHDRAWAL REQUEST SENT!'), backgroundColor: Colors.green));
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('ERROR: $e'), backgroundColor: Colors.redAccent));
                  }
                }, 
                child: const Text('CONFIRM WITHDRAWAL'),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(text, style: const TextStyle(color: AppTheme.accentColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
    );
  }
}

class TopUpBottomSheet extends StatefulWidget {
  final String uid;
  final WalletProvider wallet;
  const TopUpBottomSheet({super.key, required this.uid, required this.wallet});

  @override
  State<TopUpBottomSheet> createState() => _TopUpBottomSheetState();
}

class _TopUpBottomSheetState extends State<TopUpBottomSheet> {
  final _amountController = TextEditingController();
  final _refController = TextEditingController();
  File? _proofImage;
  bool _isSubmitting = false;

  Future<void> _pickProof() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _proofImage = File(picked.path));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 32, left: 24, right: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DEPOSIT VIA ESEWA', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5)),
            const SizedBox(height: 24),
            if (widget.wallet.config != null) ...[
              _buildEsewaDetails(widget.wallet.config!.esewaId),
              const SizedBox(height: 20),
              if (widget.wallet.config!.qrCodeUrl.isNotEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16), 
                      child: CachedNetworkImage(imageUrl: widget.wallet.config!.qrCodeUrl, height: 160)
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 32),
            _label('STEP 1: UPLOAD SCREENSHOT'),
            GestureDetector(
              onTap: _pickProof,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: _proofImage == null 
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.white24),
                        SizedBox(height: 12),
                        Text('ATTACH PAYMENT PROOF', style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ],
                    )
                  : ClipRRect(borderRadius: BorderRadius.circular(24), child: Image.file(_proofImage!, fit: BoxFit.cover)),
              ),
            ),
            const SizedBox(height: 24),
            _label('STEP 2: TRANSACTION DETAILS'),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'PAID AMOUNT (RS.)', prefixIcon: Icon(Icons.currency_rupee)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _refController,
              decoration: const InputDecoration(hintText: 'ESEWA TRANSACTION ID', prefixIcon: Icon(Icons.numbers_rounded)),
            ),
            const SizedBox(height: 40),
            _isSubmitting 
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
              : ElevatedButton(
                  onPressed: _handleSubmit, 
                  child: const Text('SUBMIT FOR VERIFICATION'),
                ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEsewaDetails(String id) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.accentColor.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.payment_rounded, color: AppTheme.accentColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ADMIN ESEWA ID', style: TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(id, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: AppTheme.accentColor, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: id));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID COPIED TO CLIPBOARD')));
            },
          )
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

  Future<void> _handleSubmit() async {
    if (_amountController.text.isEmpty || _refController.text.isEmpty || _proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PLEASE COMPLETE ALL STEPS')));
      return;
    }
    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final ref = FirebaseStorage.instance.ref()
          .child('payments')
          .child(widget.uid)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(_proofImage!);
      final url = await ref.getDownloadURL();
      final amount = double.tryParse(_amountController.text) ?? 0.0;
      final request = WalletRequestModel(
        requestId: const Uuid().v4(),
        userId: widget.uid,
        amount: amount,
        esewaRefId: _refController.text.trim(),
        screenshotUrl: url,
        status: 'pending',
        timestamp: Timestamp.now(),
      );
      await FirestoreService().submitWalletRequest(request);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('REQUEST LOGGED. VERIFICATION IN PROGRESS.'), backgroundColor: Colors.green));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('ERROR: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
