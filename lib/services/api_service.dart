import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:android_id/android_id.dart';
import '../store/auth_store.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Retrieve native device identifier dynamically
  static Future<String> getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        const androidIdPlugin = AndroidId();
        final String? androidId = await androidIdPlugin.getId();
        return androidId ?? 'flutter_device_unique_12345';
      } else if (Platform.isIOS) {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'flutter_device_unique_12345';
      }
    } catch (e) {
      // Fallback
    }
    return 'flutter_device_unique_12345';
  }

  static const String defaultBaseUrl = 'http://192.168.1.253:8000/api/mobile-banking/v1';

  String get _baseUrl {
    final custom = AuthStore().customApiUrl;
    if (custom != null && custom.isNotEmpty) {
      return custom;
    }
    final coop = AuthStore().selectedCooperative;
    if (coop != null && coop['url'] != null) {
      String url = coop['url'] as String;
      // Map port 3000 to port 8000 for mobile backend APIs
      url = url.replaceAll(':3000', ':8000');
      if (!url.endsWith('/api/mobile-banking/v1')) {
        url = url.replaceAll(RegExp(r'/$'), '') + '/api/mobile-banking/v1';
      }
      return url;
    }
    return defaultBaseUrl;
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

  // Helper response handler
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      AuthStore().clearAuth();
      throw Exception('Unauthorized. Session cleared.');
    }
    
    final body = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw Exception(body['message'] ?? 'Network API Error: ${response.statusCode}');
    }
  }

  // GET Request
  Future<dynamic> get(String endpoint, {Map<String, String>? params}) async {
    String urlStr = '$_baseUrl$endpoint';
    if (params != null && params.isNotEmpty) {
      final queryStr = Uri(queryParameters: params).query;
      urlStr += '?$queryStr';
    }
    final response = await http.get(Uri.parse(urlStr), headers: _headers);
    return _handleResponse(response);
  }

  // POST Request
  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    if (!payload.containsKey('device_id') ||
        payload['device_id'] == 'flutter_device_unique_12345' ||
        payload['device_id'] == 'mb_device_id_token') {
      payload['device_id'] = await getDeviceId();
    }
    final response = await http.post(
      Uri.parse('$_baseUrl$endpoint'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    return _handleResponse(response);
  }

  // API Call Implementations
  Future<Map<String, dynamic>> checkStatus(String mobile, String deviceId) async {
    final devId = deviceId == 'flutter_device_unique_12345' || deviceId == 'mb_device_id_token'
        ? await getDeviceId()
        : deviceId;
    return await post('/check-status', {'mobile': mobile, 'device_id': devId});
  }

  Future<Map<String, dynamic>> activateValidate(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    if (!payload.containsKey('device_id') ||
        payload['device_id'] == 'flutter_device_unique_12345' ||
        payload['device_id'] == 'mb_device_id_token') {
      payload['device_id'] = await getDeviceId();
    }
    return await post('/activate-request/validate', payload);
  }

  Future<Map<String, dynamic>> activateSendOtp(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    if (!payload.containsKey('device_id') ||
        payload['device_id'] == 'flutter_device_unique_12345' ||
        payload['device_id'] == 'mb_device_id_token') {
      payload['device_id'] = await getDeviceId();
    }
    return await post('/activate-request/send-otp', payload);
  }

  Future<Map<String, dynamic>> activateSubmit(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    if (!payload.containsKey('device_id') ||
        payload['device_id'] == 'flutter_device_unique_12345' ||
        payload['device_id'] == 'mb_device_id_token') {
      payload['device_id'] = await getDeviceId();
    }
    return await post('/activate-request/submit', payload);
  }

  Future<Map<String, dynamic>> sendDeviceLinkOtp(String mobile, String deviceId) async {
    final devId = deviceId == 'flutter_device_unique_12345' || deviceId == 'mb_device_id_token'
        ? await getDeviceId()
        : deviceId;
    return await post('/device-link/send-otp', {'mobile': mobile, 'device_id': devId});
  }

  Future<Map<String, dynamic>> submitDeviceLink(Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    if (!payload.containsKey('device_id') ||
        payload['device_id'] == 'flutter_device_unique_12345' ||
        payload['device_id'] == 'mb_device_id_token') {
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
    final devId = deviceId == 'flutter_device_unique_12345' || deviceId == 'mb_device_id_token'
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
      payload['firebase_token'] = fcmToken;
    }
    if (latitude != null && latitude.isNotEmpty) {
      payload['latitude'] = latitude;
    }
    if (longitude != null && longitude.isNotEmpty) {
      payload['longitude'] = longitude;
    }
    return await post('/login', payload);
  }

  Future<Map<String, dynamic>> logout() async {
    return await post('/logout', {});
  }

  Future<Map<String, dynamic>> getProfile() async {
    return await get('/profile');
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
    final devId = deviceId == 'flutter_device_unique_12345' || deviceId == 'mb_device_id_token'
        ? await getDeviceId()
        : deviceId;
    return await post('/register-member', {'data': formData, 'device_id': devId});
  }

  Future<Map<String, dynamic>> checkRegistrationsStatus(List<String> phoneNumbers, String deviceId) async {
    final devId = deviceId == 'flutter_device_unique_12345' || deviceId == 'mb_device_id_token'
        ? await getDeviceId()
        : deviceId;
    return await post('/check-registrations-status', {'phone_numbers': phoneNumbers, 'device_id': devId});
  }

  Future<Map<String, dynamic>> deleteRegistrationApp(String phoneNumber, String deviceId) async {
    final devId = deviceId == 'flutter_device_unique_12345' || deviceId == 'mb_device_id_token'
        ? await getDeviceId()
        : deviceId;
    return await post('/delete-registration', {'phone_number': phoneNumber, 'device_id': devId});
  }

  Future<Map<String, dynamic>> getDashboardSummary() async {
    return await get('/dashboard-summary');
  }

  Future<Map<String, dynamic>> getAccounts() async {
    return await get('/accounts');
  }

  Future<Map<String, dynamic>> getAccountLedger(String type, int id, {String? fromDate, String? toDate}) async {
    final Map<String, String> params = {};
    if (fromDate != null) params['from_date'] = fromDate;
    if (toDate != null) params['to_date'] = toDate;
    return await get('/accounts/$type/$id/ledger', params: params);
  }

  Future<List<Map<String, dynamic>>> fetchCooperatives() async {
    final List<String> firstNames = [
      "Bright", "Everest", "Lali Gurans", "Subha Laxmi", "Sajha", "Hamro", "Janakalyan", 
      "Unnatisheel", "Suryodaya", "Manaslu", "Annapurna", "Pathibhara", "Gaurishankar", 
      "Sayapatri", "Ganga Jamuna", "Budhanilkantha", "Panchakanya", "Mahila Kalyan",
      "Ujyaalo", "Samriddhi", "Swabalamban", "Pragati", "Nabodit", "Swarnim", "Navaratna",
      "Kamana", "Kalyan", "Shikhar", "Kalyankari", "Bishwas", "Sagarmatha", "Janata", 
      "Citizen", "Sahas", "Miteri", "Lumbini", "Sewa", "Gati", "Manakamana", "Kankai"
    ];

    final List<String> coopTypes = [
      "Saving & Credit Co-operative Ltd.",
      "Multipurpose Co-operative Ltd.",
      "Agricultural Co-operative Ltd.",
      "Consumer Co-operative Ltd."
    ];

    final List<String> nepalPlaces = [
      "New Baneshwor, Kathmandu", "Lalitpur Metro, Lalitpur", "Chipledhunga, Pokhara", 
      "Dharan Bazar, Sunsari", "Butwal Sub-Metro, Rupandehi", "Biratnagar, Morang", 
      "Hetauda, Makwanpur", "Bharatpur, Chitwan", "Nepalgunj, Banke", "Dhangadhi, Kailali",
      "Bhaktapur City, Bhaktapur", "Banepa, Kavre", "Damak, Jhapa", "Birtamode, Jhapa",
      "Ghorahi, Dang", "Itahari, Sunsari", "Janakpurdham, Dhanusha", "Tansen, Palpa"
    ];

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

    final List<Map<String, dynamic>> list = [];
    list.add({
      'id': 1,
      'name': "Bright Saving & Credit Co-operative Ltd.",
      'address': "New Baneshwor, Kathmandu",
      'gradient': "bg-blue-600",
      'url': defaultBaseUrl
    });

    for (int i = 2; i <= 150; i++) {
      final firstName = firstNames[i % firstNames.length];
      final coopType = coopTypes[i % coopTypes.length];
      final name = "$firstName $coopType";
      final address = nepalPlaces[i % nepalPlaces.length];
      final gradient = gradients[i % gradients.length];
      list.add({
        'id': i,
        'name': name,
        'address': address,
        'gradient': gradient,
        'url': defaultBaseUrl
      });
    }

    // Simulate network delay just like React's mock fetch API
    await Future.delayed(const Duration(milliseconds: 300));
    return list;
  }
}
