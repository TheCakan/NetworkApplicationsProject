import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? userData;

  const HistoryScreen({super.key, required this.token, this.userData});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransactionHistory();
  }

  Future<void> _loadTransactionHistory() async {
    try {
      print('📜 Loading transaction history...');

      final result = await _apiService.getHistory(widget.token);

      print('📡 History result: $result');

      if (result['success'] == true) {
        setState(() {
          _transactions = result['history'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to load history';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ History error: $e');
      setState(() {
        _errorMessage = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  // ✅ Utility function for safe type conversion
  double safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String safeToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
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
      case 'BUY':
      case 'SELL':
        return Icons.currency_exchange;
      case 'FUND':
        return Icons.account_balance_wallet;
      default:
        return Icons.receipt;
    }
  }

  String _formatTransactionType(String type) {
    switch (type) {
      case 'BUY':
        return 'Buy Currency';
      case 'SELL':
        return 'Sell Currency';
      case 'FUND':
        return 'Add Funds';
      default:
        return type;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadTransactionHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 16, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _loadTransactionHistory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _transactions.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No transactions yet',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your transaction history will appear here',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTransactionHistory,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = _transactions[index];

                          // ✅ Safe type conversion for all values
                          final type = safeToString(transaction['type']);
                          final fromCurrency =
                              safeToString(transaction['fromCurrency']);
                          final toCurrency =
                              safeToString(transaction['toCurrency']);
                          final fromAmount =
                              safeToDouble(transaction['fromAmount']);
                          final toAmount =
                              safeToDouble(transaction['toAmount']);
                          final rate = safeToDouble(transaction['rate']);
                          final date = safeToString(transaction['date']);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 2,
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getTransactionIcon(type),
                                  color: Colors.orange,
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                _formatTransactionType(type),
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
                                    '${fromAmount.toStringAsFixed(2)} $fromCurrency → ${toAmount.toStringAsFixed(2)} $toCurrency',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  Text(
                                    _formatDate(date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Rate: ${rate.toStringAsFixed(4)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'COMPLETED',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                _showTransactionDetails(transaction);
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  void _showTransactionDetails(dynamic transaction) {
    // ✅ Safe type conversion for details
    final type = safeToString(transaction['type']);
    final fromCurrency = safeToString(transaction['fromCurrency']);
    final toCurrency = safeToString(transaction['toCurrency']);
    final fromAmount = safeToDouble(transaction['fromAmount']);
    final toAmount = safeToDouble(transaction['toAmount']);
    final rate = safeToDouble(transaction['rate']);
    final date = safeToString(transaction['date']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Transaction Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Type', _formatTransactionType(type)),
            _buildDetailRow(
                'From', '${fromAmount.toStringAsFixed(2)} $fromCurrency'),
            _buildDetailRow('To', '${toAmount.toStringAsFixed(2)} $toCurrency'),
            _buildDetailRow('Exchange Rate',
                '1 $fromCurrency = ${rate.toStringAsFixed(4)} $toCurrency'),
            _buildDetailRow('Date', _formatDate(date)),
            _buildDetailRow('Status', 'COMPLETED', color: Colors.green),
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
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
