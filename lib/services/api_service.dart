import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_id/android_id.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'location_service.dart';
import '../store/auth_store.dart';
import 'biometric_signature_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'translation_service.dart';


class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final http.Client _client = kIsWeb
      ? http.Client()
      : IOClient(HttpClient()..idleTimeout = const Duration(seconds: 20));

  static String? _cachedDeviceId;
  static Map<String, String>? _cachedDeviceMetaData;
  static final Map<String, Map<String, dynamic>> _ramCache = {};
  static int _latestCacheTimestamp = 0;
  static int _lastResponseTimeMs = 0;

  // Retrieve native device identifier dynamically, or fallback to generated UUID
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null && _cachedDeviceId!.isNotEmpty) return _cachedDeviceId!;

    // 1. Try to load saved fallback device ID from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedId = prefs.getString('fallback_device_id');
      if (storedId != null && storedId.isNotEmpty) {
        _cachedDeviceId = storedId;
        return _cachedDeviceId!;
      }
    } catch (_) {}

    // 2. Try native platform device IDs (for Android/iOS only)
    try {
      if (!kIsWeb) {
        if (Platform.isAndroid) {
          const androidIdPlugin = AndroidId();
          final String? androidId = await androidIdPlugin.getId();
          _cachedDeviceId = androidId ?? '';
        } else if (Platform.isIOS) {
          final deviceInfo = DeviceInfoPlugin();
          final iosInfo = await deviceInfo.iosInfo;
          _cachedDeviceId = iosInfo.identifierForVendor ?? '';
        }
      }
    } catch (e) {
      // Fallback
    }

    // 3. Fallback: Generate random UUID for other platforms (Web, Desktop)
    if (_cachedDeviceId == null || _cachedDeviceId!.isEmpty) {
      final random = Random.secure();
      final List<int> values = List<int>.generate(16, (i) => random.nextInt(256));
      values[6] = (values[6] & 0x0f) | 0x40;
      values[8] = (values[8] & 0x3f) | 0x80;
      final StringBuffer buffer = StringBuffer();
      for (int i = 0; i < 16; i++) {
        if (i == 4 || i == 6 || i == 8 || i == 10) {
          buffer.write('-');
        }
        buffer.write(values[i].toRadixString(16).padLeft(2, '0'));
      }
      _cachedDeviceId = buffer.toString();

      // Persist generated UUID in SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('fallback_device_id', _cachedDeviceId!);
      } catch (_) {}
    }

    return _cachedDeviceId!;
  }

  static const String defaultBaseUrl = 'http://192.168.1.253:8000/api/mobile-banking/v1';

  String get _baseUrl {
    final path = dotenv.env['API_BASE'] ?? dotenv.env['APi_BASE'] ?? '/api/mobile-banking/v1';
    final cleanPath = path.startsWith('/') ? path : '/$path';

    final custom = AuthStore().customApiUrl;
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }

    if (AuthStore().isCustomApp) {
      final domain = dotenv.env['API_URL'] ?? dotenv.env['APi_URl'] ?? 'http://192.168.1.253:8000';
      final cleanDomain = domain.replaceAll(RegExp(r'/$'), '');
      return '$cleanDomain$cleanPath';
    }

    final coop = AuthStore().selectedCooperative;
    if (coop != null && coop['url'] != null) {
      final String url = coop['url'] as String;
      String domain = url;
      try {
        final uri = Uri.parse(url);
        if (uri.scheme.isNotEmpty && uri.host.isNotEmpty) {
          domain = '${uri.scheme}://${uri.host}${uri.hasPort ? ":${uri.port}" : ""}';
        } else {
          domain = url.split('/api')[0];
        }
      } catch (_) {
        domain = url.split('/api')[0];
      }
      final cleanDomain = domain.replaceAll(RegExp(r'/$'), '');
      return '$cleanDomain$cleanPath';
    }
    
    final domain = dotenv.env['API_URL'] ?? dotenv.env['APi_URl'] ?? 'http://192.168.1.253:8000';
    final cleanDomain = domain.replaceAll(RegExp(r'/$'), '');
    return '$cleanDomain$cleanPath';
  }

  Map<String, String> get _headers {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = AuthStore().token;
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<bool>? _current401Future;

  // Retrieve location and FCM token safely for biometric re-verification
  Future<Map<String, String>> _getLocationAndFcmToken() async {
    String? fcmToken;
    String? latitude;
    String? longitude;

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final messaging = FirebaseMessaging.instance;
        fcmToken = await messaging.getToken();
      } catch (_) {}
    }

    try {
      final loc = await LocationService().getLocation(forceRequestPermission: true);
      latitude = loc['latitude'];
      longitude = loc['longitude'];
    } catch (_) {}

    final Map<String, String> result = {};
    if (fcmToken != null) result['fcm_token'] = fcmToken;
    if (latitude != null) result['latitude'] = latitude;
    if (longitude != null) result['longitude'] = longitude;
    return result;
  }

  // Handle showing the session-expired dialog globally
  static Future<bool> _showExpiredDialog() async {
    final context = AuthStore.navigatorKey.currentContext;
    if (context == null) {
      await AuthStore().clearAuth();
      return false;
    }

    final isDark = AuthStore().isDarkMode;
    final mobile = AuthStore().mobile;
    final isBiometric = AuthStore().isBiometricEnabled && mobile != null;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        bool localLoading = false;
        String? errorMessage;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: isDark ? Colors.amber : Colors.amber.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Session Expired',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isBiometric
                        ? 'Your session has expired. Tap Quick Login to continue with fingerprint or face auth, or choose another action.'
                        : 'Your session has expired. Do you want to go to the login screen or stay on this screen?',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (localLoading) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                    ),
                  ],
                ],
              ),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              actions: [
                if (isBiometric) ...[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: localLoading
                        ? null
                        : () async {
                            setState(() {
                              localLoading = true;
                              errorMessage = null;
                            });
                            try {
                              final api = ApiService();
                              final challengeRes = await api.getBiometricChallenge(mobile);
                              final challenge = challengeRes['data']?['challenge'] ?? challengeRes['challenge'];
                              if (challenge == null) {
                                throw Exception('Failed to fetch biometric challenge.');
                              }

                              final signature = await BiometricSignatureService.signChallenge(mobile, challenge);

                              final devId = await ApiService.getDeviceId();
                              final extraData = await api._getLocationAndFcmToken();

                              final res = await api.verifyBiometric({
                                'mobile': mobile,
                                'signed_data': signature,
                                'device_id': devId,
                                'fcm_token': extraData['fcm_token'],
                                'latitude': extraData['latitude'],
                                'longitude': extraData['longitude'],
                              });

                              final data = res['data'] is Map ? res['data'] as Map<String, dynamic> : res;
                              final token = data['token'] ?? res['token'];
                              final responseCodeRaw = res['response_code'];
                              final int responseCode = responseCodeRaw is int
                                  ? responseCodeRaw
                                  : int.tryParse(responseCodeRaw?.toString() ?? '') ?? (token != null ? 1 : 0);

                              if (responseCode == 1 && token != null) {
                                await AuthStore().setToken(token);
                                await AuthStore().setMobile(mobile);
                                await AuthStore().setRegisteredMobile(mobile);

                                final profileRes = await api.getProfile();
                                if (profileRes['data'] != null) {
                                  await AuthStore().setProfile(profileRes['data']);
                                }

                                if (dialogCtx.mounted) {
                                  ScaffoldMessenger.of(dialogCtx).showSnackBar(
                                    const SnackBar(
                                      content: Text('Session restored successfully!'),
                                      backgroundColor: Color(0xFF10B981),
                                    ),
                                  );
                                  Navigator.of(dialogCtx).pop(true);
                                }
                              } else {
                                throw Exception(res['message'] ?? 'Biometric verification failed.');
                              }
                            } catch (e) {
                              final errStr = e.toString();
                              if (errStr.contains('cancel') || errStr.contains('Cancel') || errStr.contains('AUTH_CANCELLED') || errStr.contains('Canceled')) {
                                setState(() {
                                  localLoading = false;
                                  errorMessage = 'Authentication cancelled.';
                                });
                              } else {
                                setState(() {
                                  localLoading = false;
                                  errorMessage = errStr.replaceAll('Exception:', '').trim();
                                });
                              }
                            }
                          },
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.fingerprint, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Quick Login',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                TextButton(
                  onPressed: localLoading
                      ? null
                      : () async {
                          await AuthStore().clearAuth();
                          if (dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop(false);
                            AuthStore.navigatorKey.currentState?.pushNamedAndRemoveUntil('/', (route) => false);
                          }
                        },
                  child: Text(
                    'Go to Login',
                    style: TextStyle(
                      color: isDark ? Colors.redAccent : Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: localLoading
                      ? null
                      : () {
                          Navigator.of(dialogCtx).pop(false);
                        },
                  child: Text(
                    'Stay Here',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    return result ?? false;
  }

  // Deduplicates multiple concurrent 401 responses
  Future<bool> _handle401() async {
    if (_current401Future != null) {
      return await _current401Future!;
    }

    final completer = Completer<bool>();
    _current401Future = completer.future;

    try {
      final result = await _showExpiredDialog();
      completer.complete(result);
    } catch (_) {
      completer.complete(false);
    } finally {
      _current401Future = null;
    }

    return completer.future;
  }

  Exception _simplifyNetworkError(dynamic e) {
    if (e is SocketException) {
      return Exception('No internet connection or server is unreachable.'.tr);
    } else if (e is TimeoutException) {
      return Exception('Connection timed out. Please try again.'.tr);
    } else if (e is HandshakeException) {
      return Exception('Secure connection failed.'.tr);
    }
    
    final errStr = e.toString();
    if (errStr.contains('SocketException') || errStr.contains('Failed host lookup') || errStr.contains('Network is unreachable')) {
      return Exception('No internet connection or server is unreachable.'.tr);
    } else if (errStr.contains('TimeoutException') || errStr.contains('timeout')) {
      return Exception('Connection timed out. Please try again.'.tr);
    } else if (errStr.contains('HandshakeException') || errStr.contains('CertificateException') || errStr.contains('cert')) {
      return Exception('Secure connection failed.'.tr);
    } else if (errStr.contains('ClientException') || errStr.contains('Connection failed')) {
      return Exception('Connection failed. Please check your internet connection.'.tr);
    } else if (errStr.contains('FormatException') || errStr.contains('Unexpected character')) {
      return Exception('Server returned an invalid response. Please try again later.'.tr);
    }
    
    final cleanMsg = errStr.replaceAll('Exception:', '').trim();
    return Exception(cleanMsg.isNotEmpty ? cleanMsg : 'An unexpected network error occurred.'.tr);
  }

  // Helper response handler with retry capability
  Future<dynamic> _handleResponse(http.Response response, Future<dynamic> Function() retryCallback) async {
    if (response.statusCode == 401) {
      final isLogoutReq = response.request?.url.path.contains('/logout') ?? false;
      if (isLogoutReq) {
        try {
          return jsonDecode(response.body);
        } catch (_) {
          return {};
        }
      }

      final isGet = response.request?.method == 'GET';
      final reauthenticated = await _handle401();
      
      if (reauthenticated && isGet) {
        return await retryCallback();
      }
      throw Exception('Unauthorized. Session expired.');
    }
    
    final dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Server returned an invalid response. Please try again later.'.tr);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw Exception((body is Map ? body['message'] : null) ?? 'Network API Error: ${response.statusCode}');
    }
  }

  // Retrieve device metadata dynamically (Model and OS)
  static Future<Map<String, String>> getDeviceMetaData() async {
    if (_cachedDeviceMetaData != null) return _cachedDeviceMetaData!;
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        final brand = androidInfo.brand ?? '';
        final model = androidInfo.model ?? '';
        final manufacturer = androidInfo.manufacturer ?? '';
        
        String deviceName = '';
        if (brand.toLowerCase() == manufacturer.toLowerCase()) {
          deviceName = '${brand.toUpperCase()} $model'.trim();
        } else {
          deviceName = '${manufacturer.toUpperCase()} ${brand.toUpperCase()} $model'.trim();
        }
        
        // De-duplicate words
        final words = deviceName.split(' ');
        final uniqueWords = <String>[];
        for (var word in words) {
          if (word.isNotEmpty && !uniqueWords.contains(word)) {
            uniqueWords.add(word);
          }
        }
        deviceName = uniqueWords.join(' ');
        
        _cachedDeviceMetaData = {
          'X-Device-Model': deviceName.isNotEmpty ? deviceName : 'Android Device',
          'X-Device-Os': 'Android ${androidInfo.version.release}',
        };
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        final model = iosInfo.model ?? '';
        final machine = iosInfo.utsname.machine ?? '';
        _cachedDeviceMetaData = {
          'X-Device-Model': '$model ($machine)'.trim(),
          'X-Device-Os': 'iOS ${iosInfo.systemVersion}',
        };
      }
    } catch (e) {
      // Fallback
    }
    _cachedDeviceMetaData ??= {
      'X-Device-Model': Platform.isAndroid ? 'Android Device' : (Platform.isIOS ? 'iOS Device' : 'Unknown Device'),
      'X-Device-Os': Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : 'Unknown'),
    };
    return _cachedDeviceMetaData!;
  }

  static String _getCacheKey(String endpoint, Map<String, String>? params) {
    String key = 'api_cache_$endpoint';
    if (params != null && params.isNotEmpty) {
      final sortedKeys = params.keys.toList()..sort();
      final query = sortedKeys.map((k) => '$k=${params[k]}').join('&');
      key += '?$query';
    }
    return key;
  }

  static Future<void> saveToCache(String endpoint, Map<String, String>? params, dynamic data, int timestamp) async {
    final key = _getCacheKey(endpoint, params);
    final cacheData = {
      'timestamp': timestamp,
      'data': data,
    };
    _ramCache[key] = cacheData;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(cacheData));
      if (timestamp > _latestCacheTimestamp) {
        _latestCacheTimestamp = timestamp;
        await prefs.setInt('latest_cache_timestamp', timestamp);
      }
    } catch (e) {
      debugPrint('Error saving to cache: $e');
    }
  }

  static Future<Map<String, dynamic>?> readFromCache(String endpoint, Map<String, String>? params) async {
    final key = _getCacheKey(endpoint, params);
    Map<String, dynamic>? cachedEntry;
    if (_ramCache.containsKey(key)) {
      cachedEntry = _ramCache[key];
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        final jsonStr = prefs.getString(key);
        if (jsonStr != null) {
          cachedEntry = jsonDecode(jsonStr) as Map<String, dynamic>;
          _ramCache[key] = cachedEntry;
        }
      } catch (e) {
        debugPrint('Error reading cache: $e');
      }
    }

    if (cachedEntry != null) {
      final cachedTs = cachedEntry['timestamp'] as int? ?? 0;
      if (cachedTs == _latestCacheTimestamp) {
        return cachedEntry;
      }
    }
    return null;
  }

  static Future<void> clearCache() async {
    _ramCache.clear();
    _latestCacheTimestamp = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (var key in keys) {
        if (key.startsWith('api_cache_')) {
          await prefs.remove(key);
        }
      }
      debugPrint('✅ API cache cleared successfully.');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  static Future<void> checkAndClearCacheOnAppStart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _latestCacheTimestamp = prefs.getInt('latest_cache_timestamp') ?? 0;
      final lastCleared = prefs.getInt('api_cache_last_cleared') ?? 0;
      final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (nowSeconds - lastCleared > 24 * 3600) {
        _ramCache.clear();
        final keys = prefs.getKeys();
        for (var key in keys) {
          if (key.startsWith('api_cache_')) {
            await prefs.remove(key);
          }
        }
        await prefs.setInt('api_cache_last_cleared', nowSeconds);
        debugPrint('✅ API cache cleared on startup (24h interval)');
      }
    } catch (e) {
      debugPrint('Error checking cache duration: $e');
    }
  }

  // GET Request
  Future<dynamic> get(String endpoint, {
    Map<String, String>? params,
    Map<String, dynamic>? metadata,
  }) async {
    String urlStr = '$_baseUrl$endpoint';
    if (params != null && params.isNotEmpty) {
      final queryStr = Uri(queryParameters: params).query;
      urlStr += '?$queryStr';
    }
    final reqHeaders = Map<String, String>.from(_headers);
    reqHeaders['X-Device-Id'] = await getDeviceId();
    final meta = await getDeviceMetaData();
    reqHeaders.addAll(meta);

    final bool isCacheEnabled = AuthStore().enableCaching;
    Map<String, dynamic>? cachedEntry;
    if (isCacheEnabled) {
      cachedEntry = await readFromCache(endpoint, params);
      if (cachedEntry != null && cachedEntry['timestamp'] != null) {
        final int nowMs = DateTime.now().millisecondsSinceEpoch;
        final int elapsedMs = nowMs - _lastResponseTimeMs;
        if (elapsedMs < 10000) {
          debugPrint('⚡ Caching Optimization: Bypassed GET request to $endpoint. Serving from cache. (Elapsed: ${elapsedMs}ms)');
          if (metadata != null) {
            metadata['is304'] = true;
          }
          return cachedEntry['data'];
        }
        reqHeaders['X-Last-Updated'] = cachedEntry['timestamp'].toString();
      }
    }

    final http.Response response;
    try {
      response = await _client.get(Uri.parse(urlStr), headers: reqHeaders);
    } catch (e) {
      throw _simplifyNetworkError(e);
    }

    if (isCacheEnabled && response.statusCode == 304) {
      _lastResponseTimeMs = DateTime.now().millisecondsSinceEpoch;
      if (metadata != null) {
        metadata['is304'] = true;
      }
      if (cachedEntry != null && cachedEntry['data'] != null) {
        return cachedEntry['data'];
      }
    }

    if (response.statusCode == 401) {
      return await _handleResponse(response, () => get(endpoint, params: params, metadata: metadata));
    }

    final dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Server returned an invalid response. Please try again later.'.tr);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      _lastResponseTimeMs = DateTime.now().millisecondsSinceEpoch;
      if (isCacheEnabled) {
        final tsHeader = response.headers['x-server-timestamp'] ?? response.headers['X-Server-Timestamp'];
        final int serverTimestamp = int.tryParse(tsHeader ?? '') ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
        await saveToCache(endpoint, params, body, serverTimestamp);
      }
      return body;
    } else {
      throw Exception((body is Map ? body['message'] : null) ?? 'Network API Error: ${response.statusCode}');
    }
  }

  // POST Request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final reqHeaders = Map<String, String>.from(_headers);
    final payload = Map<String, dynamic>.from(data);
    if (!payload.containsKey('device_id') ||
        payload['device_id'] == null ||
        payload['device_id'].toString().isEmpty) {
      payload['device_id'] = await getDeviceId();
    }
    final meta = await getDeviceMetaData();
    if (!payload.containsKey('device_model')) {
      payload['device_model'] = meta['X-Device-Model'];
      // payload['device_modal'] = meta['X-Device-Model'];
      payload['device_name'] = meta['X-Device-Model'];
    }
    if (!payload.containsKey('device_os')) {
      payload['device_os'] = meta['X-Device-Os'];
      payload['device_version'] = meta['X-Device-Os'];
    }
    reqHeaders['X-Device-Id'] = await getDeviceId();
    reqHeaders.addAll(meta);
    final http.Response response;
    try {
      response = await _client.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: reqHeaders,
        body: jsonEncode(payload),
      );
    } catch (e) {
      throw _simplifyNetworkError(e);
    }
    return await _handleResponse(response, () => post(endpoint, data));
  }

  // API Call Implementations
  Future<Map<String, dynamic>> checkStatus(String mobile, String deviceId) async {
    final devId = (deviceId == null || deviceId.isEmpty)
        ? await getDeviceId()
        : deviceId;
    return await post('/check-status', {'mobile': mobile, 'device_id': devId});
  }

  Future<Map<String, dynamic>> activateValidate(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    if (!payload.containsKey('device_id') ||
        payload['device_id'] == null ||
        payload['device_id'].toString().isEmpty) {
      payload['device_id'] = await getDeviceId();
    }
    return await post('/activate-request/validate', payload);
  }

  Future<Map<String, dynamic>> activateSendOtp(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    if (!payload.containsKey('device_id') ||
        payload['device_id'] == null ||
        payload['device_id'].toString().isEmpty) {
      payload['device_id'] = await getDeviceId();
    }
    return await post('/activate-request/send-otp', payload);
  }

  Future<Map<String, dynamic>> activateSubmit(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    if (!payload.containsKey('device_id') ||
        payload['device_id'] == null ||
        payload['device_id'].toString().isEmpty) {
      payload['device_id'] = await getDeviceId();
    }
    return await post('/activate-request/submit', payload);
  }

  Future<Map<String, dynamic>> sendDeviceLinkOtp(String mobile, String deviceId) async {
    final devId = (deviceId == null || deviceId.isEmpty)
        ? await getDeviceId()
        : deviceId;
    return await post('/device-link/send-otp', {'mobile': mobile, 'device_id': devId});
  }

  Future<Map<String, dynamic>> submitDeviceLink(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    if (!payload.containsKey('device_id') ||
        payload['device_id'] == null ||
        payload['device_id'].toString().isEmpty) {
      payload['device_id'] = await getDeviceId();
    }
    return await post('/device-link/verify-otp', payload);
  }

  Future<Map<String, dynamic>> login(
    String mobile,
    String pin,
    String deviceId, {
    String? fcmToken,
    String? latitude,
    String? longitude,
  }) async {
    final devId = (deviceId == null || deviceId.isEmpty)
        ? await getDeviceId()
        : deviceId;
    final payload = {
      'mobile': mobile,
      'pin': pin,
      'password': pin,
      'device_id': devId
    };
    if (fcmToken != null && fcmToken.isNotEmpty) {
      payload['fcm_token'] = fcmToken;
    }
    if (latitude != null && latitude.isNotEmpty) {
      payload['latitude'] = latitude;
    }
    if (longitude != null && longitude.isNotEmpty) {
      payload['longitude'] = longitude;
    }
    return await post('/login', payload);
  }

  Future<Map<String, dynamic>> resetSetupCredentials(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    if (!payload.containsKey('device_id') ||
        payload['device_id'] == null ||
        payload['device_id'].toString().isEmpty) {
      payload['device_id'] = await getDeviceId();
    }
    return await post('/reset-setup-credentials', payload);
  }

  Future<Map<String, dynamic>> logout() async {
    return await post('/logout', {});
  }

  Future<Map<String, dynamic>> getProfile() async {
    return await get('/profile');
  }

  Future<Map<String, dynamic>> getMemberDetails() async {
    return await get('/member-details');
  }

  Future<Map<String, dynamic>> getCooperativeDetails() async {
    return await get('/cooperative-details');
  }

  Future<Map<String, dynamic>> getBiometricChallenge(String mobile) async {
    return await post('/biometric/challenge', {'mobile': mobile});
  }

  Future<Map<String, dynamic>> verifyBiometric(Map<String, dynamic> data) async {
    return await post('/biometric/verify', data);
  }

  Future<Map<String, dynamic>> registerBiometric(String publicKey) async {
    return await post('/biometric/register', {'public_key': publicKey});
  }

  Future<Map<String, dynamic>> registerMember(Map<String, dynamic> formData, String deviceId) async {
    final devId = (deviceId == null || deviceId.isEmpty)
        ? await getDeviceId()
        : deviceId;
    return await post('/register-member', {'data': formData, 'device_id': devId});
  }

  Future<Map<String, dynamic>> checkRegistrationsStatus(List<String> phoneNumbers, String deviceId) async {
    final devId = (deviceId == null || deviceId.isEmpty)
        ? await getDeviceId()
        : deviceId;
    return await post('/check-registrations-status', {'phone_numbers': phoneNumbers, 'device_id': devId});
  }

  Future<Map<String, dynamic>> deleteRegistrationApp(String phoneNumber, String deviceId) async {
    final devId = (deviceId == null || deviceId.isEmpty)
        ? await getDeviceId()
        : deviceId;
    return await post('/delete-registration', {'phone_number': phoneNumber, 'device_id': devId});
  }

  Future<Map<String, dynamic>> getAccounts() async {
    return await get('/accounts');
  }

  Future<Map<String, dynamic>> getSavingSchemeRateLogs(int schemeId) async {
    return await get('/accounts/saving-scheme-rate-logs', params: {'saving_scheme_id': schemeId.toString()});
  }

  Future<Map<String, dynamic>> getLoanSchemeRateLogs(int schemeId) async {
    return await get('/accounts/loan-scheme-rate-logs', params: {'loan_scheme_id': schemeId.toString()});
  }

  Future<Map<String, dynamic>> getLoanPaymentSchedules(int accountId) async {
    return await get('/accounts/loan-payment-schedules', params: {'loan_account_id': accountId.toString()});
  }

  Future<Map<String, dynamic>> getAccountLedger(String type, int id, {String? fromDate, String? toDate, String? preset}) async {
    final Map<String, String> params = {};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    if (preset != null) params['preset'] = preset;
    return await get('/accounts/$type/$id/ledger', params: params);
  }

  Future<Map<String, dynamic>> getAllAccountsLedger({String? fromDate, String? toDate, String? preset}) async {
    final Map<String, String> params = {};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    if (preset != null) params['preset'] = preset;
    return await get('/accounts/all-ledger', params: params);
  }

  Future<void> saveCooperativesToFile(List<Map<String, dynamic>> list) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/cooperatives_list.json');
      await file.writeAsString(jsonEncode(list));
    } catch (e) {
      debugPrint('Failed to save cooperatives to file: $e');
    }
  }

  Future<List<Map<String, dynamic>>?> loadCooperativesFromFile() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/cooperatives_list.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> decoded = jsonDecode(content);
        return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    } catch (e) {
      debugPrint('Failed to load cooperatives from file: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> fetchCooperatives({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cachedList = await loadCooperativesFromFile();
      if (cachedList != null && cachedList.isNotEmpty) {
        return cachedList;
      }
    }

    final apiUrl = dotenv.env['COOPERATIVE_LIST_API'] ?? 'https://erp.bright-gps.com.np/sahakari-clients?token=IVYF623EYEROP0LGHRXOXYHIDIMJ9F';
    final List<String> gradients = [
      "bg-blue-600",
      "bg-emerald-600",
      "bg-purple-600",
      "bg-rose-600",
      "bg-cyan-600",
      "bg-amber-600",
      "bg-indigo-600",
      "bg-teal-600"
    ];

    String? networkError;

    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(const Duration(seconds: 20));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded['data'] ?? [];
        final List<Map<String, dynamic>> mappedList = [];
        
        for (int i = 0; i < data.length; i++) {
          final client = data[i];
          final String name = client['name'] ?? 'Unnamed Sahakari';
          
          mappedList.add({
            'id': i + 1,
            'name': name,
            'address': client['address'] ?? 'Nepal',
            'url': client['api_url'] ?? '',
            'api_url': client['api_url'] ?? '',
            'logoUrl': client['logo_img_path'] ?? '',
            'logo_url': client['logo_img_path'] ?? '',
            'logo_name': client['logo_name'] ?? '',
            'gradient': gradients[i % gradients.length],
          });
        }
        
        if (mappedList.isNotEmpty) {
          await saveCooperativesToFile(mappedList);
          return mappedList;
        } else {
          networkError = 'Empty client list returned from API';
        }
      } else {
        networkError = 'Server returned status code: ${response.statusCode}';
      }
    } catch (e) {
      networkError = _simplifyNetworkError(e).toString().replaceAll('Exception: ', '');
      debugPrint('Failed to fetch cooperatives from network: $e');
    }

    if (forceRefresh) {
      throw Exception(networkError);
    }

    final cachedFallback = await loadCooperativesFromFile();
    if (cachedFallback != null && cachedFallback.isNotEmpty) {
      return cachedFallback;
    }

    throw Exception('${"Failed to load cooperatives".tr}: $networkError. ${"Please pull down to refresh again.".tr}');
  }

  Future<Map<String, dynamic>> getNotices({int page = 1, int perPage = 20}) async {
    return await get('/notices', params: {
      'page': page.toString(),
      'perPage': perPage.toString(),
    });
  }

  Stream<ApiStreamResponse<T>> streamGet<T>(
    String endpoint, {
    Map<String, String>? params,
    required T Function(dynamic json) parser,
    bool forceRefresh = false,
  }) async* {
    final bool isCacheEnabled = AuthStore().enableCaching;
    Map<String, dynamic>? cachedEntry;

    if (isCacheEnabled) {
      cachedEntry = await readFromCache(endpoint, params);
      if (!forceRefresh && cachedEntry != null && cachedEntry['data'] != null) {
        try {
          final parsed = parser(cachedEntry['data']);
          yield ApiStreamResponse<T>(data: parsed, isLoading: false);
        } catch (_) {}
      }
    }

    bool isNetworkDone = false;
    Timer? loadingTimer;
    
    final controller = StreamController<ApiStreamResponse<T>>(
      onCancel: () {
        loadingTimer?.cancel();
      },
    );

    final bool hasCache = cachedEntry != null && cachedEntry['data'] != null;
    if (forceRefresh) {
      controller.add(ApiStreamResponse<T>(isLoading: true));
    } else if (hasCache) {
      loadingTimer = Timer(const Duration(seconds: 1), () {
        if (!isNetworkDone) {
          try {
            final parsed = parser(cachedEntry!['data']);
            controller.add(ApiStreamResponse<T>(data: parsed, isLoading: true));
          } catch (_) {
            controller.add(ApiStreamResponse<T>(isLoading: true));
          }
        }
      });
    } else {
      controller.add(ApiStreamResponse<T>(isLoading: true));
    }

    final Map<String, dynamic> networkMetadata = {};
    get(endpoint, params: params, metadata: networkMetadata).then((freshData) {
      isNetworkDone = true;
      loadingTimer?.cancel();
      try {
        final parsed = parser(freshData);
        final is304 = networkMetadata['is304'] == true;
        controller.add(ApiStreamResponse<T>(
          data: parsed,
          isLoading: false,
          isCacheNotModified: is304,
        ));
      } catch (e) {
        controller.add(ApiStreamResponse<T>(
          isLoading: false,
          hasError: true,
          error: e.toString(),
        ));
      }
      controller.close();
    }).catchError((e) {
      isNetworkDone = true;
      loadingTimer?.cancel();
      if (hasCache) {
        try {
          final parsed = parser(cachedEntry!['data']);
          controller.add(ApiStreamResponse<T>(
            data: parsed,
            isLoading: false,
            hasError: true,
            error: e.toString(),
          ));
        } catch (_) {
          controller.add(ApiStreamResponse<T>(
            isLoading: false,
            hasError: true,
            error: e.toString(),
          ));
        }
      } else {
        controller.add(ApiStreamResponse<T>(
          isLoading: false,
          hasError: true,
          error: e.toString(),
        ));
      }
      controller.close();
    });

    yield* controller.stream;
  }

  Stream<ApiStreamResponse<Map<String, dynamic>>> getAllAccountsLedgerStream({
    String? fromDate,
    String? toDate,
    String? preset,
    bool forceRefresh = false,
  }) {
    final Map<String, String> params = {};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    if (preset != null) params['preset'] = preset;

    return streamGet<Map<String, dynamic>>(
      '/accounts/all-ledger',
      params: params,
      parser: (json) => json as Map<String, dynamic>,
      forceRefresh: forceRefresh,
    );
  }

  Stream<ApiStreamResponse<Map<String, dynamic>>> getNoticesStream({
    int page = 1,
    int perPage = 20,
    bool forceRefresh = false,
  }) {
    return streamGet<Map<String, dynamic>>(
      '/notices',
      params: {
        'page': page.toString(),
        'perPage': perPage.toString(),
      },
      parser: (json) => json as Map<String, dynamic>,
      forceRefresh: forceRefresh,
    );
  }

  Stream<ApiStreamResponse<Map<String, dynamic>>> getAccountLedgerStream(
    String type,
    int id, {
    String? fromDate,
    String? toDate,
    String? preset,
    bool forceRefresh = false,
  }) {
    final Map<String, String> params = {};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    if (preset != null) params['preset'] = preset;

    return streamGet<Map<String, dynamic>>(
      '/accounts/$type/$id/ledger',
      params: params,
      parser: (json) => json as Map<String, dynamic>,
      forceRefresh: forceRefresh,
    );
  }

  Stream<ApiStreamResponse<Map<String, dynamic>>> getSavingSchemeRateLogsStream(
    int schemeId, {
    bool forceRefresh = false,
  }) {
    return streamGet<Map<String, dynamic>>(
      '/accounts/saving-scheme-rate-logs',
      params: {'saving_scheme_id': schemeId.toString()},
      parser: (json) => json as Map<String, dynamic>,
      forceRefresh: forceRefresh,
    );
  }

  Stream<ApiStreamResponse<Map<String, dynamic>>> getLoanSchemeRateLogsStream(
    int schemeId, {
    bool forceRefresh = false,
  }) {
    return streamGet<Map<String, dynamic>>(
      '/accounts/loan-scheme-rate-logs',
      params: {'loan_scheme_id': schemeId.toString()},
      parser: (json) => json as Map<String, dynamic>,
      forceRefresh: forceRefresh,
    );
  }

  Stream<ApiStreamResponse<Map<String, dynamic>>> getLoanPaymentSchedulesStream(
    int accountId, {
    bool forceRefresh = false,
  }) {
    return streamGet<Map<String, dynamic>>(
      '/accounts/loan-payment-schedules',
      params: {'loan_account_id': accountId.toString()},
      parser: (json) => json as Map<String, dynamic>,
      forceRefresh: forceRefresh,
    );
  }

  Stream<ApiStreamResponse<Map<String, dynamic>>> getHolidaysStream({
    required int yearBs,
    required int monthBs,
    bool forceRefresh = false,
  }) {
    return streamGet<Map<String, dynamic>>(
      '/holidays',
      params: {
        'year_bs': yearBs.toString(),
        'month_bs': monthBs.toString(),
      },
      parser: (json) => json as Map<String, dynamic>,
      forceRefresh: forceRefresh,
    );
  }
}

class ApiStreamResponse<T> {
  final T? data;
  final bool isLoading;
  final bool hasError;
  final String? error;
  final bool isCacheNotModified;

  ApiStreamResponse({
    this.data,
    required this.isLoading,
    this.hasError = false,
    this.error,
    this.isCacheNotModified = false,
  });
}
