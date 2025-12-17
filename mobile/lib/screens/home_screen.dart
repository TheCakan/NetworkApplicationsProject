import 'package:flutter/material.dart';
import 'exchange_screen.dart';
import 'history_screen.dart';
import 'login_screen.dart';
import 'package:mobile/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.token, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _balances;
  Map<String, dynamic>? _rates;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;

    setState(() {
      if (!_isRefreshing) {
        _isLoading = true;
      }
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getBalance(widget.token),
        _apiService.getRates(),
      ], eagerError: true);

      if (!mounted) return;

      final balanceResult = results[0];
      final ratesResult = results[1];

      if (balanceResult['success'] == true && ratesResult['success'] == true) {
        setState(() {
          _balances = balanceResult['balances'];
          _rates = ratesResult['rates'];
        });
      } else {
        final error = balanceResult['error'] ??
            ratesResult['error'] ??
            'Failed to load data';
        throw Exception(error);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Failed to load data. Please pull down to refresh.";
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  // ✅ NULL SAFE: Add Funds method
  void _addFunds() {
    // Early context references to avoid null issues
    final navigatorState = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final amountController = TextEditingController();
        bool isAdding = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: const Text('Add Funds'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Enter the amount in PLN to add to your wallet.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (PLN)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.money),
                      hintText: '0.00',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isAdding
                      ? null
                      : () {
                          navigatorState.pop();
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isAdding
                      ? null
                      : () async {
                          setStateDialog(() => isAdding = true);

                          try {
                            final amountText = amountController.text.trim();
                            if (amountText.isEmpty) {
                              throw Exception('Please enter an amount');
                            }

                            final amount = double.tryParse(amountText);
                            if (amount == null || amount <= 0) {
                              throw Exception(
                                  'Please enter a valid amount greater than 0');
                            }

                            final result = await _apiService.addFunds(
                                widget.token, amount);

                            if (result['success'] == true) {
                              // Close dialog first
                              navigatorState.pop();

                              // Then refresh data
                              await _fetchData();

                              // Show success message
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${amount.toStringAsFixed(2)} PLN added successfully'),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            } else {
                              throw Exception(
                                  result['error'] ?? 'Failed to add funds');
                            }
                          } catch (e) {
                            // Show error message
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(e
                                    .toString()
                                    .replaceFirst("Exception: ", "")),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 3),
                              ),
                            );

                            // Only reset loading state if dialog is still open
                            if (navigatorState.canPop()) {
                              setStateDialog(() => isAdding = false);
                            }
                          }
                        },
                  child: isAdding
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Add Funds'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showRates() {
    if (_rates == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exchange rates not available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Current Exchange Rates'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _rates!.entries
                .where((entry) => entry.key != 'PLN')
                .map((entry) {
              final rateValue = _safeToDouble(entry.value);
              return _buildRateRow(
                  '${entry.key}/PLN', rateValue.toStringAsFixed(4));
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // ✅ SAFE UTILITY FUNCTIONS
  double _safeToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  String _safeToString(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    return value.toString();
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

  @override
  Widget build(BuildContext context) {
    // ✅ NULL SAFE: Total balance calculation
    double totalBalance = 0.0;
    if (_balances != null && _rates != null) {
      _balances!.forEach((currency, amount) {
        final amountValue = _safeToDouble(amount);
        final rateValue = _safeToDouble(_rates![currency]);
        totalBalance += amountValue * (rateValue != 0 ? rateValue : 1.0);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Exchange'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style:
                              const TextStyle(fontSize: 16, color: Colors.red),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _fetchData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      setState(() => _isRefreshing = true);
                      await _fetchData();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Info Card
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(children: [
                                const Icon(Icons.account_circle,
                                    size: 40, color: Colors.blue),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome, ${_safeToString(widget.user['name'])}!',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      Text(
                                        _safeToString(widget.user['email']),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Balance Card
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
                                  Text(
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
                                      children: (_balances ?? {})
                                          .entries
                                          .map((entry) {
                                        final amount =
                                            _safeToDouble(entry.value);
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8.0),
                                          child: _buildBalanceChip(
                                            entry.key,
                                            amount.toStringAsFixed(2),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Transactions Section
                          const Text(
                            'Transactions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Menu Grid
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
                                    if (_balances != null && _rates != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ExchangeScreen(
                                            token: widget.token,
                                            userData: {
                                              'wallets': _balances,
                                              'user': widget.user,
                                              'rates': _rates,
                                            },
                                          ),
                                        ),
                                      ).then((_) {
                                        if (mounted) _fetchData();
                                      });
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Please wait for data to load'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
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
                                          userData: {'user': widget.user},
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                _buildMenuCard(
                                  'View Rates',
                                  Icons.trending_up,
                                  Colors.blue,
                                  _showRates,
                                ),
                                _buildMenuCard(
                                  'Add Funds',
                                  Icons.account_balance_wallet,
                                  Colors.purple,
                                  _addFunds,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }

  Widget _buildBalanceChip(String currency, String amount) {
    return Chip(
      backgroundColor: Colors.blue.shade50,
      label: Text('$amount $currency'),
      labelStyle: TextStyle(
        color: Colors.blue.shade700,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildMenuCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
