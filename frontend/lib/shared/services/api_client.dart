import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int status;
  final String message;
  ApiException(this.status, this.message);
  @override
  String toString() => message;
}

class ApiClient {
  // Android emulator: 10.0.2.2 ; iOS sim / web / desktop: 127.0.0.1
  static String baseUrl = 'http://127.0.0.1:8001';

  static String? _token;

  static Future<void> loadToken() async {
    final sp = await SharedPreferences.getInstance();
    _token = sp.getString('access_token');
  }

  static Future<void> saveToken(String? token) async {
    _token = token;
    final sp = await SharedPreferences.getInstance();
    if (token == null) {
      await sp.remove('access_token');
    } else {
      await sp.setString('access_token', token);
    }
  }

  static bool get isLoggedIn => _token != null;
  static String? get token => _token;

  static Map<String, String> _headers() {
    final h = {'Content-Type': 'application/json'};
    if (_token != null) h['Authorization'] = 'Bearer $_token';
    return h;
  }

  static Future<dynamic> get(String path) async {
    final res = await http.get(Uri.parse('$baseUrl$path'), headers: _headers());
    return _decode(res);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final res = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    return _decode(res);
  }

  static Future<dynamic> delete(String path) async {
    final res =
        await http.delete(Uri.parse('$baseUrl$path'), headers: _headers());
    return _decode(res);
  }

  static dynamic _decode(http.Response res) {
    final body = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final msg = (body is Map && body['detail'] != null)
        ? body['detail'].toString()
        : 'HTTP ${res.statusCode}';
    throw ApiException(res.statusCode, msg);
  }

  static String wsUrl(String path, String token) =>
      '${baseUrl.replaceFirst('http', 'ws')}$path?token=$token';
}
