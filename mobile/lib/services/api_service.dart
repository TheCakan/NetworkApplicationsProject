import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  // Base URL - Android emulator ve web için
  String get _baseUrl {
    if (kIsWeb) {
      // Web için localhost kullan
      return 'http://localhost:8080';
    } else {
      // Android/iOS için emulator host kullan
      return 'http://10.0.2.2:8080';
    }
  }
  
  ApiService() {
    // Debug: Hangi platform ve URL kullanıldığını göster
    print('🌐 Platform: ${kIsWeb ? "Web" : "Mobile"}');
    print('🔗 Base URL: $_baseUrl');
  }

  // Test connection
  Future<bool> testConnection() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Login - Kullanıcı girişi
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/api/login');

    try {
      print('🔐 Login attempt: $email');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('📡 Login response: ${response.statusCode}');
      print('📡 Login body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'token': data['token'],
          'user': data['user'],
          'message': data['message']
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Login failed'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Register - Yeni kullanıcı kaydı
  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final url = Uri.parse('$_baseUrl/api/register');

    try {
      print('👤 Register attempt: $email');
      print('🌐 Using URL: $url');
      print('🔍 kIsWeb: $kIsWeb');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      print('📡 Register response: ${response.statusCode}');
      print('📡 Register body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'token': data['token'],
          'user': data['user'],
          'message': data['message']
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      print('❌ Register error: $e');
      print('❌ Register error type: ${e.runtimeType}');
      print('❌ Attempted URL: $url');
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get Rates - Güncel döviz kurlarını çek
  Future<Map<String, dynamic>> getRates() async {
    try {
      // Backend'de /api/rates/historical endpoint'ini kullan
      final url = Uri.parse('$_baseUrl/api/rates/historical?days=1');

      print('💹 Fetching rates from NBP API');

      final response = await http.get(url);

      print('📡 Rates response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Backend response formatına göre işle
        if (data['data'] != null && data['data'].isNotEmpty) {
          final latestRates = data['data'][0]; // En güncel kurlar
          return {
            'success': true,
            'rates': {
              'USD': latestRates['USD'] ?? 4.0,
              'EUR': latestRates['EUR'] ?? 4.3,
              'GBP': latestRates['GBP'] ?? 5.1,
              'PLN': 1.0
            }
          };
        }
      }

      // Fallback rates
      return {
        'success': true,
        'rates': {'USD': 4.15, 'EUR': 4.52, 'GBP': 5.28, 'PLN': 1.0}
      };
    } catch (e) {
      print('❌ Rates error: $e');
      // Fallback rates
      return {
        'success': true,
        'rates': {'USD': 4.15, 'EUR': 4.52, 'GBP': 5.28, 'PLN': 1.0}
      };
    }
  }

  // Get Balance - Kullanıcının bakiyesini çek
  Future<Map<String, dynamic>> getBalance(String token) async {
    final url = Uri.parse('$_baseUrl/api/balance');

    try {
      print('💰 Balance request');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Balance response: ${response.statusCode}');
      print('📡 Balance body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'balances': data['balances'],
          'message': data['message']
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to load balance'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get History - İşlem geçmişini çek
  Future<Map<String, dynamic>> getHistory(String token) async {
    final url = Uri.parse('$_baseUrl/api/history');

    try {
      print('📜 History request');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 History response: ${response.statusCode}');
      print('📡 History body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'history': data['history'],
          'message': data['message']
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to load history'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Add Funds - Hesaba para ekle
  Future<Map<String, dynamic>> addFunds(String token, double amount) async {
    final url = Uri.parse('$_baseUrl/api/addfunds');

    try {
      print('💵 Add funds: $amount PLN');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'amount': amount}),
      );

      print('📡 Add funds response: ${response.statusCode}');
      print('📡 Add funds body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'],
          'amount': data['amount'],
          'currency': data['currency'] ?? 'PLN'
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Failed to add funds'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Execute Exchange - Döviz alım/satım işlemi - FIXED VERSION
  Future<Map<String, dynamic>> executeExchange(
    String token,
    String fromCurrency,
    String toCurrency,
    double amount,
  ) async {
    final url = Uri.parse('$_baseUrl/api/exchange');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fromCurrency': fromCurrency,
          'toCurrency': toCurrency,
          'amount': amount,
          // ✅ rate GÖNDERİLMİYOR! Backend hesaplayacak!
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Exchange failed.');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
