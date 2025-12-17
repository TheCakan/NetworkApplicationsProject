import 'package:flutter/material.dart';
import 'login_screen.dart';

class HistoryScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? userData;

  const HistoryScreen({super.key, required this.token, this.userData});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactionHistory();
  }

  Future<void> _loadTransactionHistory() async {
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _transactions = [
        {
          'id': 1,
          'type': 'EXCHANGE',
          'fromCurrency': 'PLN',
          'toCurrency': 'USD',
          'fromAmount': 100.0,
          'toAmount': 23.81,
          'rate': 4.20,
          'date': '2024-01-15 14:30:25',
          'status': 'COMPLETED',
        },
        {
          'id': 2,
          'type': 'EXCHANGE',
          'fromCurrency': 'EUR',
          'toCurrency': 'PLN',
          'fromAmount': 50.0,
          'toAmount': 225.0,
          'rate': 4.50,
          'date': '2024-01-14 10:15:42',
          'status': 'COMPLETED',
        },
        {
          'id': 3,
          'type': 'ADD_FUNDS',
          'fromCurrency': 'PLN',
          'toCurrency': 'PLN',
          'fromAmount': 1000.0,
          'toAmount': 1000.0,
          'rate': 1.0,
          'date': '2024-01-13 09:05:18',
          'status': 'COMPLETED',
        },
      ];
      _isLoading = false;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'FAILED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'EXCHANGE':
        return Icons.currency_exchange;
      case 'ADD_FUNDS':
        return Icons.account_balance_wallet;
      default:
        return Icons.receipt;
    }
  }

  // DÜZELTME: Logout butonu çalışması için
  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          // DÜZELTME: Logout butonu eklendi
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? const Center(
                  child: Text(
                    'No transactions found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _transactions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getTransactionIcon(transaction['type']),
                            color: Colors.orange,
                            size: 24,
                          ),
                        ),
                        title: Text(
                          '${transaction['type']?.replaceAll('_', ' ') ?? 'Transaction'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${transaction['fromAmount']} ${transaction['fromCurrency']} → ${transaction['toAmount']} ${transaction['toCurrency']}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              transaction['date'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(transaction['status'])
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            transaction['status'] ?? '',
                            style: TextStyle(
                              color: _getStatusColor(transaction['status']),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        onTap: () {
                          _showTransactionDetails(transaction);
                        },
                      ),
                    );
                  },
                ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
                'Type', transaction['type']?.replaceAll('_', ' ') ?? ''),
            _buildDetailRow('From',
                '${transaction['fromAmount']} ${transaction['fromCurrency']}'),
            _buildDetailRow('To',
                '${transaction['toAmount']} ${transaction['toCurrency']}'),
            _buildDetailRow('Rate',
                '1 ${transaction['fromCurrency']} = ${transaction['rate']} ${transaction['toCurrency']}'),
            _buildDetailRow('Date', transaction['date'] ?? ''),
            _buildDetailRow('Status', transaction['status'] ?? '',
                color: _getStatusColor(transaction['status'])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: color != null ? FontWeight.w500 : null,
            ),
          ),
        ],
      ),
    );
  }
}
