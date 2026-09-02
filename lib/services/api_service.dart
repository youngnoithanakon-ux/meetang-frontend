import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // IP เธเธญเธเน€เธเธฃเธทเนเธญเธเธเธญเธกเธเธดเธงเน€เธ•เธญเธฃเน เน€เธเธทเนเธญเนเธซเนเธกเธทเธญเธ–เธทเธญเน€เธเธทเนเธญเธกเธ•เนเธญเน€เธเนเธฒเธกเธฒเนเธ”เน
  static const String serverIp = 'meetang.heyroll.site';
  static const String baseUrl = 'https://$serverIp/api';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // ---- Save Wallet Order Locally ----
  Future<List<int>> getWalletOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final order = prefs.getString('wallet_order');
    if (order != null) {
      return List<int>.from(jsonDecode(order));
    }
    return [];
  }

  Future<void> saveWalletOrder(List<int> orderedIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wallet_order', jsonEncode(orderedIds));
  }

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: _headers(null),
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveToken(data['access_token']);
      return data;
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: _headers(null),
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await saveToken(data['access_token']);
      return data;
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      await http.post(Uri.parse('$baseUrl/logout'), headers: _headers(token));
      await removeToken();
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final token = await getToken();
    final response = await http.get(Uri.parse('$baseUrl/user'), headers: _headers(token));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load profile');
  }

  Future<void> updateUserProfile(String name, String? password) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/user'),
      headers: _headers(token),
      body: jsonEncode({
        'name': name,
        if (password != null && password.isNotEmpty) 'password': password,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update profile');
    }
  }

  Future<List<dynamic>> getWallets() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/wallets'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load wallets');
    }
  }

  Future<List<dynamic>> getCategories() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> data, {dynamic imageFile}) async {
    final token = await getToken();
    
    if (imageFile != null) {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/transactions'));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      
      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });
      
      // imageFile is XFile from image_picker
      var bytes = await imageFile.readAsBytes();
      var pic = http.MultipartFile.fromBytes('image', bytes, filename: imageFile.name);
      request.files.add(pic);
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create transaction: ${response.body}');
      }
    } else {
      final response = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: _headers(token),
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create transaction: ${response.body}');
      }
    }
  }

  Future<List<dynamic>> getTransactions({int? month, int? year}) async {
    final token = await getToken();
    
    String url = '$baseUrl/transactions';
    if (month != null && year != null) {
      url += '?month=$month&year=$year';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _headers(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  Future<Map<String, dynamic>> updateTransaction(int id, Map<String, dynamic> data, {dynamic imageFile}) async {
    final token = await getToken();
    
    // Laravel PUT with Multipart requires _method=PUT hack
    if (imageFile != null) {
      data['_method'] = 'PUT';
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/transactions/$id'));
      request.headers.addAll({
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });
      
      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });
      
      var bytes = await imageFile.readAsBytes();
      var pic = http.MultipartFile.fromBytes('image', bytes, filename: imageFile.name);
      request.files.add(pic);
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update transaction: ${response.body}');
      }
    } else {
      final response = await http.put(
        Uri.parse('$baseUrl/transactions/$id'),
        headers: _headers(token),
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update transaction: ${response.body}');
      }
    }
  }

  Future<void> deleteTransaction(int id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/transactions/$id'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete transaction: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createWallet(String name, double initialBalance, {double? targetAmount}) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/wallets'),
      headers: _headers(token),
      body: jsonEncode({
        'name': name,
        'balance': initialBalance,
        if (targetAmount != null) 'target_amount': targetAmount,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create wallet: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateWallet(int id, String name, double balance, {double? targetAmount}) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/wallets/$id'),
      headers: _headers(token),
      body: jsonEncode({
        'name': name,
        'balance': balance,
        'target_amount': targetAmount,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update wallet: ${response.body}');
    }
  }

  Future<void> deleteWallet(int id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/wallets/$id'),
      headers: _headers(token),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete wallet: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> updateCategory(String id, Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: _headers(token),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update category: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> createCategory(String name, String type) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: _headers(token),
      body: jsonEncode({'name': name, 'type': type}),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to create category: ${response.body}');
  }

  Future<void> deleteCategory(int id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete category: ${response.body}');
    }
  }

  // ---- Recurring Transactions ----
  Future<void> processRecurrings() async {
    final token = await getToken();
    await http.post(
      Uri.parse('$baseUrl/process-recurrings'),
      headers: _headers(token),
    );
  }

  Future<List<dynamic>> getRecurringTransactions() async {
    final token = await getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/recurring-transactions'),
      headers: _headers(token),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load recurrings');
    }
  }

  Future<void> createRecurringTransaction(Map<String, dynamic> data) async {
    final token = await getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/recurring-transactions'),
      headers: _headers(token),
      body: jsonEncode(data),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to create recurring transaction: ${response.body}');
    }
  }

  Future<void> deleteRecurringTransaction(int id) async {
    final token = await getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/recurring-transactions/$id'),
      headers: _headers(token),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete recurring transaction: ${response.body}');
    }
  }
}

