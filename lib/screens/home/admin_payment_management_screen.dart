import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../services/firestore_service.dart';

class AdminPaymentManagementScreen extends StatefulWidget {
  const AdminPaymentManagementScreen({super.key});

  @override
  State<AdminPaymentManagementScreen> createState() => _AdminPaymentManagementScreenState();
}

class _AdminPaymentManagementScreenState extends State<AdminPaymentManagementScreen> {
  final FirestoreService _firestore = FirestoreService();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(title: const Text('Payment Ledger')),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: StreamBuilder<List<TransactionModel>>(
              stream: _firestore.getAllTransactions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                var list = snapshot.data ?? [];
                
                // Apply Search
                if (_searchQuery.isNotEmpty) {
                  list = list.where((tx) => tx.txnId.contains(_searchQuery) || tx.userId.contains(_searchQuery)).toList();
                }
                
                // Apply Type Filter
                if (_selectedFilter == 'Credits') {
                  list = list.where((tx) => tx.type == 'credit').toList();
                } else if (_selectedFilter == 'Debits') {
                  list = list.where((tx) => tx.type == 'debit').toList();
                }

                if (list.isEmpty) {
                  return const Center(child: Text('No transactions found', style: TextStyle(color: Colors.white24)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (ctx, index) {
                    final tx = list[index];
                    return _buildTransactionCard(tx);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search Txn ID or User ID...',
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: Colors.black26,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['All', 'Credits', 'Debits'].map((f) {
              final isSelected = _selectedFilter == f;
              return GestureDetector(
                onTap: () => setState(() => _selectedFilter = f),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6E00FF) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? Colors.transparent : Colors.white10),
                  ),
                  child: Text(f, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel tx) {
    final isCredit = tx.type == 'credit';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tx.description, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text(
                '${isCredit ? '+' : '-'} Rs. ${tx.amount.toInt()}',
                style: TextStyle(color: isCredit ? Colors.greenAccent : Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Txn ID: ${tx.txnId}', style: const TextStyle(color: Colors.white24, fontSize: 10)),
          Text('User: ${tx.userId}', style: const TextStyle(color: Colors.white24, fontSize: 10)),
          const SizedBox(height: 8),
          Text(
            DateFormat('dd MMM yyyy, hh:mm a').format(tx.timestamp.toDate()),
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
