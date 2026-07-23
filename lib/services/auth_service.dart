import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _tokenKey = 'staff_auth_token';
  static const String _usernameKey = 'staff_username';
  static const String _isAdminKey = 'staff_is_admin';
  static const String baseUrl = 'http://obam.begenchcargo.com';

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/api/auth/login/'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'username': username, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final token = data['token'] as String;
      final isAdmin = data['is_superuser'] as bool? ?? false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_usernameKey, username);
      await prefs.setBool(_isAdminKey, isAdmin);
      return {'success': true, 'token': token, 'is_admin': isAdmin};
    } else {
      return {'success': false, 'error': 'Ulanyjy ady ýa-da açar söz ýalňyş'};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_isAdminKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isAdminKey) ?? false;
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
