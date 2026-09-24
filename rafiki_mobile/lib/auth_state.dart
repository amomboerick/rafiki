// rafiki_mobile/lib/auth_state.dart
import 'package:flutter/material.dart';
import 'api_service.dart';

/// Global auth state — pure Dart, no packages required.
/// Session is held in memory only (cleared on page refresh).
class AuthState extends ChangeNotifier {
  static final AuthState instance = AuthState._();
  AuthState._();

  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _token != null && _user != null;

  Future<void> login(String phone, String password) async {
    final result = await ApiService.login(phone: phone, password: password);
    _token = result['access_token'] as String;
    _user = result['user'] as Map<String, dynamic>;
    notifyListeners();
  }

  Future<void> register({
    required String fullName,
    required String phone,
    required String password,
    required String role,
    String county = 'Nairobi',
    String? subCounty,
  }) async {
    final result = await ApiService.register(
      fullName: fullName,
      phone: phone,
      password: password,
      role: role,
      county: county,
      subCounty: subCounty,
    );
    _token = result['access_token'] as String;
    _user = result['user'] as Map<String, dynamic>;
    notifyListeners();
  }

  void logout() {
    _token = null;
    _user = null;
    notifyListeners();
  }
}