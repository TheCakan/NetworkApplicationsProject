import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final bool isAuthError;

  ApiException(this.message, this.statusCode, {this.isAuthError = false});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8080/api';

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {'success': true};
      return json.decode(response.body);
    } else {
      try {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error'] ?? 'Unknown error';
        final isAuthError = response.statusCode == 401 || response.statusCode == 403;
        throw ApiException(errorMessage, response.statusCode, isAuthError: isAuthError);
      } catch (e) {
        throw ApiException('HTTP ${response.statusCode}', response.statusCode);
      }
    }
  }

  Future<String> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final data = _handleResponse(response);
      return data['token'];
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<String> register(String email, String password) async {
    try {
      final name = email.split('@').first;
      
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final data = _handleResponse(response);
      return data['token'];
    } catch (e) {
      print('Register error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfile(String token) async {
    try {
      final balanceResponse = await http.get(
        Uri.parse('$baseUrl/balance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final balanceData = _handleResponse(balanceResponse);
      
      return {
        'success': true,
        'data': {
          'user': {
            'wallets': balanceData['balances']
          }
        }
      };
    } catch (e) {
      print('Profile error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getBalance(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/balance'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      print('Balance error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getExchangeRates() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.nbp.pl/api/exchangerates/tables/A/?format=json'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data[0]['rates'];
        
        Map<String, double> exchangeRates = {'PLN': 1.0};
        for (var rate in rates) {
          if (['USD', 'EUR', 'GBP'].contains(rate['code'])) {
            exchangeRates[rate['code']] = rate['mid'].toDouble();
          }
        }

        return {
          'success': true,
          'data': {
            'rates': exchangeRates,
            'effectiveDate': data[0]['effectiveDate']
          }
        };
      } else {
        throw ApiException('Failed to fetch rates', response.statusCode);
      }
    } catch (e) {
      print('Exchange rates error: $e');
      return {
        'success': true,
        'data': {
          'rates': {
            'USD': 4.20,
            'EUR': 4.50,
            'GBP': 5.30,
            'PLN': 1.00,
          },
          'effectiveDate': DateTime.now().toIso8601String()
        }
      };
    }
  }

  Future<Map<String, dynamic>> getTransactionHistory(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      print('Transaction history error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> executeTransaction({
    required String token,
    required String type,
    required String fromCurrency,
    required String toCurrency,
    required double fromAmount,
  }) async {
    try {
      final ratesResponse = await getExchangeRates();
      final rates = ratesResponse['data']['rates'] as Map<String, dynamic>;
      
      final fromRate = rates[fromCurrency] ?? 1.0;
      final toRate = rates[toCurrency] ?? 1.0;
      
      final amountInPLN = fromAmount * fromRate;
      final toAmount = amountInPLN / toRate;
      final exchangeRate = toRate / fromRate;

      final response = await http.post(
        Uri.parse('$baseUrl/exchange'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'type': type,
          'fromCurrency': fromCurrency,
          'fromAmount': fromAmount,
          'toCurrency': toCurrency,
          'toAmount': toAmount,
          'rate': exchangeRate,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      print('Execute transaction error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addFunds({
    required String token,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/addfunds'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'amount': amount,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      print('Add funds error: $e');
      rethrow;
    }
  }
}