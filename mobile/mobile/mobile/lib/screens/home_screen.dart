import 'package:flutter/material.dart';
import 'exchange_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.token, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, double> _balances = {
    'PLN': 0.0,
    'USD': 0.0,
    'EUR': 0.0,
    'GBP': 0.0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBalances();
  }

  Future<void> _loadBalances() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _balances = {
        'PLN': 1500.0,
        'USD': 250.0,
        'EUR': 180.0,
        'GBP': 120.0,
      };
      _isLoading = false;
    });
  }

  // DÜZELTME: Para yatırma işlemi için kullanıcıdan miktar alınacak
  void _addFunds() {
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Funds (PLN)'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount',
            hintText: 'Enter amount to deposit',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              double amount = double.tryParse(amountController.text) ?? 0.0;
              if (amount > 0) {
                Navigator.pop(context);
                setState(() {
                  _balances['PLN'] = (_balances['PLN'] ?? 0) + amount;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$amount PLN added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add Funds'),
          ),
        ],
      ),
    );
  }

  void _showRates(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Current Exchange Rates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildRateRow('USD/PLN', '4.20'),
            _buildRateRow('EUR/PLN', '4.50'),
            _buildRateRow('GBP/PLN', '5.30'),
            _buildRateRow('CHF/PLN', '4.70'),
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

  Widget _buildRateRow(String pair, String rate) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(pair, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(rate, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // DÜZELTME: Logout butonu çalışması için
  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalBalance = (_balances['PLN'] ?? 0.0) +
        (_balances['USD'] ?? 0.0) * 4.2 +
        (_balances['EUR'] ?? 0.0) * 4.5 +
        (_balances['GBP'] ?? 0.0) * 5.3;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Exchange'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // DÜZELTME: Logout butonu eklendi
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.account_circle,
                          size: 40, color: Colors.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${widget.user['name'] ?? 'User'}!',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              widget.user['email'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Balance',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : Text(
                              '${totalBalance.toStringAsFixed(2)} PLN',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                      const SizedBox(height: 16),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildBalanceChip('PLN',
                                _balances['PLN']?.toStringAsFixed(2) ?? '0.00'),
                            const SizedBox(width: 8),
                            _buildBalanceChip('USD',
                                _balances['USD']?.toStringAsFixed(2) ?? '0.00'),
                            const SizedBox(width: 8),
                            _buildBalanceChip('EUR',
                                _balances['EUR']?.toStringAsFixed(2) ?? '0.00'),
                            const SizedBox(width: 8),
                            _buildBalanceChip('GBP',
                                _balances['GBP']?.toStringAsFixed(2) ?? '0.00'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Transactions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.0,
                  children: [
                    _buildMenuCard(
                      'Exchange',
                      Icons.currency_exchange,
                      Colors.green,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExchangeScreen(
                              token: widget.token,
                              userData: {
                                'wallets': _balances,
                                'user': widget.user,
                              },
                            ),
                          ),
                        ).then((_) {
                          _loadBalances();
                        });
                      },
                    ),
                    _buildMenuCard(
                      'History',
                      Icons.history,
                      Colors.orange,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HistoryScreen(
                              token: widget.token,
                              userData: {
                                'user': widget.user,
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    _buildMenuCard(
                      'View Rates',
                      Icons.trending_up,
                      Colors.blue,
                      () {
                        _showRates(context);
                      },
                    ),
                    _buildMenuCard(
                      'Add Funds',
                      Icons.account_balance_wallet,
                      Colors.purple,
                      _addFunds, // DÜZELTME: Yeni para yatırma metodu
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

  Widget _buildBalanceChip(String currency, String amount) {
    return Chip(
      backgroundColor: Colors.blue.shade50,
      label: Text('$amount $currency'),
      labelStyle: TextStyle(color: Colors.blue.shade700, fontSize: 12),
    );
  }

  Widget _buildMenuCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: color),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
