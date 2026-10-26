import 'package:flutter/foundation.dart';
import '../../shared/models/user.dart';
import '../../shared/services/api_client.dart';

class AuthState extends ChangeNotifier {
  AppUser? user;
  bool loading = false;

  bool get isLoggedIn => user != null;

  Future<void> init() async {
    await ApiClient.loadToken();
    if (ApiClient.isLoggedIn) {
      try {
        final data = await ApiClient.get('/auth/me');
        user = AppUser.fromJson(data);
      } catch (_) {
        await ApiClient.saveToken(null);
        user = null;
      }
      notifyListeners();
    }
  }

  Future<void> login(String phone, String password) async {
    loading = true;
    notifyListeners();
    try {
      final data = await ApiClient.post(
          '/auth/login', {'phone': phone, 'password': password});
      await ApiClient.saveToken(data['access_token']);
      final me = await ApiClient.get('/auth/me');
      user = AppUser.fromJson(me);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String phone,
    required String password,
    required String fullName,
    required String role,
    String? city,
    String? country,
  }) async {
    loading = true;
    notifyListeners();
    try {
      await ApiClient.post('/auth/register', {
        'phone': phone,
        'password': password,
        'full_name': fullName,
        'role': role,
        'city': city,
        'country': country,
      });
      await login(phone, password);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    try {
      final data = await ApiClient.get('/auth/me');
      user = AppUser.fromJson(data);
      notifyListeners();
    } catch (e) {
      debugPrint('Refresh user error: \$e');
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    loading = true;
    notifyListeners();
    try {
      final res = await ApiClient.patch('/auth/me', data);
      user = AppUser.fromJson(res);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiClient.saveToken(null);
    user = null;
    notifyListeners();
  }
}
