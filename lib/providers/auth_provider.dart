import 'package:flutter/foundation.dart';
import '../models/auth.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthProvider with ChangeNotifier {
  Auth? _auth;
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadAuthFromPrefs();
  }

  Auth? get auth => _auth;
  User? get user => _auth?.user;
  String? get token => _auth?.token;
  bool get isAuthenticated => _auth != null;

  Future<void> _loadAuthFromPrefs() async {
    print('AuthProvider: Loading auth from prefs...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userJson = prefs.getString('user');
      if (token != null && userJson != null) {
        _auth = Auth(token: token, user: User.fromJson(jsonDecode(userJson)));
        print('AuthProvider: Loaded user from prefs.');
      } else {
        print('AuthProvider: No user found in prefs.');
      }
    } catch (e) {
      print('AuthProvider: Error loading from prefs: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      print('AuthProvider: isLoading set to false.');
    }
  }

  Future<void> _saveAuthToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_auth != null) {
      await prefs.setString('token', _auth!.token);
      await prefs.setString('user', jsonEncode(_auth!.user.toJson()));
    }
  }

  Future<void> _clearAuthFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  @override
  Future<void> signup(String name, String email, String password) async {
    try {
      await _authService.signup(name, email, password);
      // Do NOT set _auth or save to prefs here!
      // User will log in after signup.
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> login(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      _auth = await _authService.login(email, password);
      await _saveAuthToPrefs();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  @override
  Future<void> getCurrentUser() async {
    if (_auth == null) return;
    try {
      final user = await _authService.getCurrentUser(_auth!.token);
      _auth = Auth(token: _auth!.token, user: user);
      await _saveAuthToPrefs();
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  @override
  void logout() {
    _auth = null;
    _clearAuthFromPrefs();
    _isLoading = false;
    notifyListeners();
  }
} 