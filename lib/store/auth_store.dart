import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthStore extends ChangeNotifier with WidgetsBindingObserver {
  static final AuthStore _instance = AuthStore._internal();
  factory AuthStore() => _instance;
  AuthStore._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  String? _token;
  String? _mobile;
  String? _registeredMobile;
  Map<String, dynamic>? _selectedCooperative;
  Map<String, dynamic>? _profile;
  String? _customApiUrl;
  bool _preferencesSetupCompleted = false;

  // App settings & preferences
  String _language = 'en';
  bool _isBiometricEnabled = false;
  bool _neverAskBiometric = false;
  String? _biometricType;
  bool _pushEnabled = true;
  bool _smsAlertsEnabled = true;
  String _dailyLimit = '50000';
  String _themeMode = 'system'; // 'system', 'dark', 'light'

  String? get token => _token;
  String? get mobile => _mobile;
  String? get registeredMobile => _registeredMobile;
  
  bool get isCustomApp => !kIsWeb && Platform.isAndroid && dotenv.env['IS_CUSTOM_APP'] == 'true';
  bool get preferencesSetupCompleted => _preferencesSetupCompleted;

  Map<String, dynamic>? get selectedCooperative {
    if (isCustomApp) {
      final domain = dotenv.env['API_URL'] ?? dotenv.env['APi_URl'] ?? 'http://192.168.1.253:8000';
      final path = dotenv.env['API_BASE'] ?? dotenv.env['APi_BASE'] ?? '/api/mobile-banking/v1';
      final cleanDomain = domain.replaceAll(RegExp(r'/$'), '');
      final cleanPath = path.startsWith('/') ? path : '/$path';
      final fullUrl = '$cleanDomain$cleanPath';

      final enName = dotenv.env['COOPERATIVE_NAME'] ?? 'Bright Saving & Credit Co-operative Ltd.';
      final neName = dotenv.env['COOPERATIVE_NAME_NEPALI'] ?? 'ब्राइट बचत तथा ऋण सहकारी संस्था लि.';
      final logoUrl = dotenv.env['COOPERATIVE_LOGO_URL'] ?? '';

      return {
        'id': 1,
        'name': _language == 'ne' ? neName : enName,
        'address': _language == 'ne' ? 'काठमाडौं, नेपाल' : 'Kathmandu, Nepal',
        'gradient': 'bg-blue-600',
        'url': fullUrl,
        'logo_url': logoUrl,
      };
    }
    return _selectedCooperative;
  }
  
  Map<String, dynamic>? get profile => _profile;
  String? get customApiUrl => _customApiUrl;

  String get language => _language;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get neverAskBiometric => _neverAskBiometric;
  String? get biometricType => _biometricType;
  bool get pushEnabled => _pushEnabled;
  bool get smsAlertsEnabled => _smsAlertsEnabled;
  String get dailyLimit => _dailyLimit;
  String get themeMode => _themeMode;

  bool get isDarkMode {
    if (kDebugMode && debugBrightnessOverride != null) {
      return debugBrightnessOverride == Brightness.dark;
    }
    if (_themeMode == 'system') {
      return ui.PlatformDispatcher.instance.platformBrightness == ui.Brightness.dark;
    }
    return _themeMode == 'dark';
  }

  @override
  void didChangePlatformBrightness() {
    if (_themeMode == 'system') {
      notifyListeners();
    }
  }

  bool get isAuthenticated => _token != null;
  bool get hasCooperative => isCustomApp || _selectedCooperative != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    // Keep token in-memory only (never load from persistence on startup)
    _token = null;
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
    _biometricType = prefs.getString('biometricType');
    _pushEnabled = prefs.getBool('pushEnabled') ?? true;
    _smsAlertsEnabled = prefs.getBool('smsAlertsEnabled') ?? true;
    _dailyLimit = prefs.getString('dailyLimit') ?? '50000';
    _themeMode = prefs.getString('themeMode') ?? 'system';
    _language = prefs.getString('language') ?? 'en';
    _preferencesSetupCompleted = prefs.getBool('preferences_setup_completed') ?? false;

    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', value);
    notifyListeners();
  }

  Future<void> setPreferencesSetupCompleted(bool value) async {
    _preferencesSetupCompleted = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('preferences_setup_completed', value);
    notifyListeners();
  }

  Future<void> setThemeMode(String value) async {
    _themeMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', value);
    notifyListeners();
  }

  // Backward compat convenience
  Future<void> setDarkMode(bool value) async {
    await setThemeMode(value ? 'dark' : 'light');
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

  Future<void> setBiometricType(String? type) async {
    _biometricType = type;
    final prefs = await SharedPreferences.getInstance();
    if (type != null) {
      await prefs.setString('biometricType', type);
    } else {
      await prefs.remove('biometricType');
    }
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
    _biometricType = null;
    _pushEnabled = true;
    _smsAlertsEnabled = true;
    _dailyLimit = '50000';
    _themeMode = 'system';
    _preferencesSetupCompleted = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }
}
