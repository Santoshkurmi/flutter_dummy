import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStore extends ChangeNotifier {
  static final AuthStore _instance = AuthStore._internal();
  factory AuthStore() => _instance;
  AuthStore._internal();

  String? _token;
  String? _mobile;
  String? _registeredMobile;
  Map<String, dynamic>? _selectedCooperative;
  Map<String, dynamic>? _profile;
  String? _customApiUrl;

  // App settings & preferences
  bool _isBiometricEnabled = false;
  bool _neverAskBiometric = false;
  bool _pushEnabled = true;
  bool _smsAlertsEnabled = true;
  String _dailyLimit = '50000';

  String? get token => _token;
  String? get mobile => _mobile;
  String? get registeredMobile => _registeredMobile;
  Map<String, dynamic>? get selectedCooperative => _selectedCooperative;
  Map<String, dynamic>? get profile => _profile;
  String? get customApiUrl => _customApiUrl;

  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get neverAskBiometric => _neverAskBiometric;
  bool get pushEnabled => _pushEnabled;
  bool get smsAlertsEnabled => _smsAlertsEnabled;
  String get dailyLimit => _dailyLimit;

  bool get isAuthenticated => _token != null;
  bool get hasCooperative => _selectedCooperative != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _mobile = prefs.getString('auth_mobile');
    _registeredMobile = prefs.getString('registeredMobile');
    _customApiUrl = prefs.getString('customApiUrl');
    
    final coopStr = prefs.getString('selected_cooperative');
    if (coopStr != null) {
      try {
        _selectedCooperative = jsonDecode(coopStr);
      } catch (_) {}
    }
    
    final profileStr = prefs.getString('user_profile');
    if (profileStr != null) {
      try {
        _profile = jsonDecode(profileStr);
      } catch (_) {}
    }

    _isBiometricEnabled = prefs.getBool('isBiometricEnabled') ?? false;
    _neverAskBiometric = prefs.getBool('neverAskBiometric') ?? false;
    _pushEnabled = prefs.getBool('pushEnabled') ?? true;
    _smsAlertsEnabled = prefs.getBool('smsAlertsEnabled') ?? true;
    _dailyLimit = prefs.getString('dailyLimit') ?? '50000';

    notifyListeners();
  }

  Future<void> setCustomApiUrl(String? url) async {
    _customApiUrl = url;
    final prefs = await SharedPreferences.getInstance();
    if (url != null && url.isNotEmpty) {
      await prefs.setString('customApiUrl', url);
    } else {
      await prefs.remove('customApiUrl');
    }
    notifyListeners();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    _isBiometricEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isBiometricEnabled', enabled);
    notifyListeners();
  }

  Future<void> setNeverAskBiometric(bool neverAsk) async {
    _neverAskBiometric = neverAsk;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('neverAskBiometric', neverAsk);
    notifyListeners();
  }

  Future<void> setPushEnabled(bool enabled) async {
    _pushEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pushEnabled', enabled);
    notifyListeners();
  }

  Future<void> setSmsAlertsEnabled(bool enabled) async {
    _smsAlertsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('smsAlertsEnabled', enabled);
    notifyListeners();
  }

  Future<void> setDailyLimit(String limit) async {
    _dailyLimit = limit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('dailyLimit', limit);
    notifyListeners();
  }

  Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token);
    } else {
      await prefs.remove('auth_token');
    }
    notifyListeners();
  }

  Future<void> setMobile(String? mobile) async {
    _mobile = mobile;
    final prefs = await SharedPreferences.getInstance();
    if (mobile != null) {
      await prefs.setString('auth_mobile', mobile);
    } else {
      await prefs.remove('auth_mobile');
    }
    notifyListeners();
  }

  Future<void> setRegisteredMobile(String? mobile) async {
    _registeredMobile = mobile;
    final prefs = await SharedPreferences.getInstance();
    if (mobile != null) {
      await prefs.setString('registeredMobile', mobile);
    } else {
      await prefs.remove('registeredMobile');
    }
    notifyListeners();
  }

  Future<void> setSelectedCooperative(Map<String, dynamic>? cooperative) async {
    _selectedCooperative = cooperative;
    final prefs = await SharedPreferences.getInstance();
    if (cooperative != null) {
      await prefs.setString('selected_cooperative', jsonEncode(cooperative));
    } else {
      await prefs.remove('selected_cooperative');
    }
    notifyListeners();
  }

  Future<void> setProfile(Map<String, dynamic>? profile) async {
    _profile = profile;
    final prefs = await SharedPreferences.getInstance();
    if (profile != null) {
      await prefs.setString('user_profile', jsonEncode(profile));
    } else {
      await prefs.remove('user_profile');
    }
    notifyListeners();
  }

  Future<void> clearAuth() async {
    _token = null;
    _profile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_profile');
    notifyListeners();
  }

  Future<void> clearAll() async {
    _token = null;
    _mobile = null;
    _registeredMobile = null;
    _selectedCooperative = null;
    _profile = null;
    _isBiometricEnabled = false;
    _neverAskBiometric = false;
    _pushEnabled = true;
    _smsAlertsEnabled = true;
    _dailyLimit = '50000';
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
