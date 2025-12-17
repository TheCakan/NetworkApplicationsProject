import 'package:flutter/material.dart';
import 'login_screen.dart';

class ExchangeScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? userData;

  const ExchangeScreen({super.key, required this.token, this.userData});

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String _fromCurrency = 'PLN';
  String _toCurrency = 'USD';
  bool _isLoading = false;

  Map<String, double> _wallets = {
    'PLN': 0.0,
    'USD': 0.0,
    'EUR': 0.0,
    'GBP': 0.0,
    'CHF': 0.0,
  };

  final Map<String, double> _rates = {
    'USD': 4.20,
    'EUR': 4.50,
    'GBP': 5.30,
    'PLN': 1.00,
    'CHF': 4.70,
  };

  @override
  void initState() {
    super.initState();
    _initializeWallets();
  }

  void _initializeWallets() {
    if (widget.userData != null && widget.userData!['wallets'] != null) {
      setState(() {
        _wallets = Map<String, double>.from(widget.userData!['wallets']);
      });
    } else {
      setState(() {
        _wallets = {
          'PLN': 1000.0,
          'USD': 50.0,
          'EUR': 40.0,
          'GBP': 30.0,
          'CHF': 20.0,
        };
      });
    }
  }

  double _calculateResult() {
    if (_amountController.text.isEmpty) return 0.0;
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    double fromRate = _rates[_fromCurrency] ?? 1.0;
    double toRate = _rates[_toCurrency] ?? 1.0;
    double inPLN = amount * fromRate;
    double result = inPLN / toRate;
    return result;
  }

  double _calculateRate() {
    double fromRate = _rates[_fromCurrency] ?? 1.0;
    double toRate = _rates[_toCurrency] ?? 1.0;
    return toRate / fromRate;
  }

  void _swapCurrencies() {
    setState(() {
      String temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _amountController.clear();
    });
  }

  void _showConfirmationDialog() {
    double result = _calculateResult();
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    double rate = _calculateRate();

    if (result == 0.0 || amount == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    double availableBalance = _wallets[_fromCurrency] ?? 0.0;
    if (availableBalance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Insufficient balance. Available: ${availableBalance.toStringAsFixed(2)} $_fromCurrency',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Exchange'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You are exchanging:'),
            const SizedBox(height: 10),
            Text(
              '${_amountController.text} $_fromCurrency',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 5),
            const Icon(Icons.arrow_downward, color: Colors.blue),
            const SizedBox(height: 5),
            Text(
              '${result.toStringAsFixed(2)} $_toCurrency',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 15),
            Text(
              'Exchange Rate: 1 $_fromCurrency = ${rate.toStringAsFixed(4)} $_toCurrency',
            ),
            const SizedBox(height: 10),
            const Divider(),
            const SizedBox(height: 5),
            Text(
              'Current Balance: ${availableBalance.toStringAsFixed(2)} $_fromCurrency',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _executeExchange(amount, result, rate);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Confirm Exchange'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeExchange(
      double fromAmount, double toAmount, double rate) async {
    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _wallets[_fromCurrency] = (_wallets[_fromCurrency] ?? 0.0) - fromAmount;
      _wallets[_toCurrency] = (_wallets[_toCurrency] ?? 0.0) + toAmount;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Successfully exchanged ${fromAmount.toStringAsFixed(2)} $_fromCurrency to ${toAmount.toStringAsFixed(2)} $_toCurrency'),
        backgroundColor: Colors.green,
      ),
    );

    _amountController.clear();
  }

  // DÜZELTME: Logout butonu çalışması için
  void _logout() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    double result = _calculateResult();
    double rate = _calculateRate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Exchange'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // DÜZELTME: Logout butonu eklendi
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // ... mevcut widget'lar aynı kalacak ...
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Wallets',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _wallets.entries.map((entry) {
                          return Chip(
                            backgroundColor: Colors.green.shade50,
                            label: Text(
                              '${entry.value.toStringAsFixed(2)} ${entry.key}',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'From',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _fromCurrency,
                                  items: _wallets.keys.map((currency) {
                                    return DropdownMenuItem(
                                      value: currency,
                                      child: Text(currency),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _fromCurrency = value!;
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Amount',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    border: const OutlineInputBorder(),
                                    suffixText: _fromCurrency,
                                    suffixStyle: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      IconButton(
                        onPressed: _swapCurrencies,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                          ),
                          child:
                              const Icon(Icons.swap_vert, color: Colors.green),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'To',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  initialValue: _toCurrency,
                                  items: _wallets.keys.map((currency) {
                                    return DropdownMenuItem(
                                      value: currency,
                                      child: Text(currency),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _toCurrency = value!;
                                    });
                                  },
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    contentPadding:
                                        EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'You Get',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    result > 0
                                        ? '${result.toStringAsFixed(2)} $_toCurrency'
                                        : '0.00 $_toCurrency',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.green, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '1 $_fromCurrency = ${rate.toStringAsFixed(4)} $_toCurrency',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed:
                              _isLoading ? null : _showConfirmationDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Exchange',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
