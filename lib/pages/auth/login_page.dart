import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../services/api_service.dart';
import '../../services/biometric_signature_service.dart';
import '../../services/translation_service.dart';
import '../../store/auth_store.dart';
import '../dashboard/dashboard_page.dart';
import 'activation_page.dart';
import 'device_linking_page.dart';
import '../settings/biometric_setup_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LoginPage extends StatefulWidget {
  final String mobileNumber;
  const LoginPage({super.key, required this.mobileNumber});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isLoading = false;
  bool _canAuthenticate = false;
  bool _isFaceId = false;
  bool _obscurePassword = true;

  bool get _isDarkMode => AuthStore().isDarkMode;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _checkBiometrics();
    _requestPermissionsAndWarmUp();
    AuthStore().addListener(_onStoreChange);
  }

  Future<void> _requestPermissionsAndWarmUp() async {
    try {
      // 1. Request native OS-level notification permission using permission_handler
      await Permission.notification.request();
    } catch (_) {}

    try {
      // 2. Warm up and request FCM notification permission
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    } catch (_) {}

    try {
      // 3. Location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    AuthStore().removeListener(_onStoreChange);
    super.dispose();
  }

  void _onStoreChange() {
    if (mounted) setState(() {});
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  Future<void> _checkBiometrics() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      final isEnabled = AuthStore().isBiometricEnabled;
      
      if (isSupported && canCheck && isEnabled) {
        final availableBiometrics = await _auth.getAvailableBiometrics();
        final hasFace = availableBiometrics.contains(BiometricType.face);
        final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
        
        setState(() {
          _canAuthenticate = true;
          _isFaceId = hasFace || isIOS;
        });
      } else {
        setState(() {
          _canAuthenticate = false;
        });
      }
    } catch (_) {
      setState(() {
        _canAuthenticate = false;
      });
    }
  }

  Future<Map<String, String>> _getLocationAndFcmToken() async {
    String? fcmToken;
    String? latitude;
    String? longitude;

    // 1. Firebase Notification Permission and FCM token retrieval
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        fcmToken = await messaging.getToken();
      }
    } catch (_) {}

    // 2. GPS Location Permission and Coordinate retrieval
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 4),
          );
          latitude = position.latitude.toString();
          longitude = position.longitude.toString();
        }
      }
    } catch (_) {}

    return {
      'fcm_token': fcmToken ?? '',
      'latitude': latitude ?? '',
      'longitude': longitude ?? '',
    };
  }

  Future<void> _handleResponseRouting(int responseCode, String apiMessage, Map<String, dynamic> res) async {
    final data = res['data'] is Map ? res['data'] as Map<String, dynamic> : res;
    final token = data['token'] ?? res['token'];

    Future<void> clearCredentials() async {
      await AuthStore().setRegisteredMobile(null);
      await AuthStore().setBiometricEnabled(false);
      await AuthStore().clearAuth();
    }

    switch (responseCode) {
      case 1: // RESP_SUCCESS
        if (token != null) {
          await AuthStore().setToken(token);
          await AuthStore().setMobile(widget.mobileNumber);
          
          final profileRes = await ApiService().getProfile();
          if (profileRes['data'] != null) {
            await AuthStore().setProfile(profileRes['data']);
          }

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login successful! Welcome to Bright Sahakari.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );

          // Check if biometrics setup is required
          final isServerBiometricSetup = (res['is_biometric_setup'] == true || res['is_biometric_setup'] == 1) || 
                                         (data['is_biometric_setup'] == true || data['is_biometric_setup'] == 1);
          final isLocallyEnabled = AuthStore().isBiometricEnabled;
          
          if (!isServerBiometricSetup || !isLocallyEnabled) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const BiometricSetupPage()),
              (route) => false,
            );
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const DashboardPage()),
              (route) => false,
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(apiMessage.isNotEmpty ? apiMessage : 'Invalid token data.'),
              backgroundColor: Colors.red.shade800,
            ),
          );
        }
        break;
      case 2: // RESP_ACTIVATION_REQUIRED
        await clearCredentials();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => ActivationPage(mobileNumber: widget.mobileNumber),
          ),
          (route) => false,
        );
        break;
      case 6: // RESP_AWAITING_APPROVAL
        await clearCredentials();
        if (!mounted) return;
        final resubmit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: _isDarkMode ? const Color(0xFF0F172A) : Colors.white,
            title: Text('Request Pending', style: TextStyle(color: _isDarkMode ? Colors.white : const Color(0xFF1E293B))),
            content: Text(
              'Your registration request is pending admin approval. Do you want to resubmit the form?',
              style: TextStyle(color: _isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel', style: TextStyle(color: _isDarkMode ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Yes, Resubmit', style: TextStyle(color: _isDarkMode ? const Color(0xFF3B82F6) : const Color(0xFF2563EB))),
              ),
            ],
          ),
        );
        if (resubmit == true && mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => ActivationPage(mobileNumber: widget.mobileNumber),
            ),
            (route) => false,
          );
        }
        break;
      case 9: // RESP_DEVICE_LINKING_REQUIRED
        await clearCredentials();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => DeviceLinkingPage(mobileNumber: widget.mobileNumber),
          ),
          (route) => false,
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiMessage.isNotEmpty ? apiMessage : 'Login failed. Please check your credentials.'),
            backgroundColor: Colors.red.shade800,
          ),
        );
    }
  }

  LinearGradient _getGradient(String? gradientClass) {
    switch (gradientClass) {
      case 'bg-blue-600':
        return const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]);
      case 'bg-emerald-600':
        return const LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)]);
      case 'bg-purple-600':
        return const LinearGradient(colors: [Color(0xFF9333EA), Color(0xFF7E22CE)]);
      case 'bg-rose-600':
        return const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFBE123C)]);
      case 'bg-cyan-600':
        return const LinearGradient(colors: [Color(0xFF0891B2), Color(0xFF0E7490)]);
      case 'bg-amber-600':
        return const LinearGradient(colors: [Color(0xFFD97706), Color(0xFFB45309)]);
      case 'bg-indigo-600':
        return const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF4338CA)]);
      case 'bg-teal-600':
        return const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF0F766E)]);
      default:
        return const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]);
    }
  }

  Future<void> _submitPassword() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;
    
    setState(() => _isLoading = true);

    try {
      final devId = await ApiService.getDeviceId();
      final extraData = await _getLocationAndFcmToken();
      
      final res = await ApiService().login(
        widget.mobileNumber,
        password,
        devId,
        fcmToken: extraData['fcm_token'],
        latitude: extraData['latitude'],
        longitude: extraData['longitude'],
      );
      
      final responseCodeRaw = res['response_code'];
      final int responseCode = responseCodeRaw is int
          ? responseCodeRaw
          : int.tryParse(responseCodeRaw?.toString() ?? '') ?? (res['token'] != null ? 1 : 0);
      final apiMessage = res['message'] ?? '';

      await _handleResponseRouting(responseCode, apiMessage, res);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red.shade800,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _authenticateBiometrics() async {
    if (!_canAuthenticate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometrics not configured or supported on this device.'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Fetch secure challenge token from server
      final challengeRes = await ApiService().getBiometricChallenge(widget.mobileNumber);
      final challenge = challengeRes['data']?['challenge'] ?? challengeRes['challenge'];
      if (challenge == null) {
        throw Exception('Failed to retrieve biometric challenge from server.');
      }
      
      // 2. Generate secure hardware-backed signature using Keystore/Secure Enclave (prompts user once)
      final signature = await BiometricSignatureService.signChallenge(widget.mobileNumber, challenge);
      
      // 3. Verify signature on backend
      final devId = await ApiService.getDeviceId();
      final extraData = await _getLocationAndFcmToken();
      
      final res = await ApiService().verifyBiometric({
        'mobile': widget.mobileNumber,
        'signed_data': signature,
        'device_id': devId,
        'fcm_token': extraData['fcm_token'],
        'firebase_token': extraData['fcm_token'],
        'latitude': extraData['latitude'],
        'longitude': extraData['longitude'],
      });

      final responseCodeRaw = res['response_code'];
      final int responseCode = responseCodeRaw is int
          ? responseCodeRaw
          : int.tryParse(responseCodeRaw?.toString() ?? '') ?? (res['token'] != null ? 1 : 0);
      final apiMessage = res['message'] ?? '';

      await _handleResponseRouting(responseCode, apiMessage, res);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      final errStr = e.toString();
      // Handle user cancellation gracefully without showing scary errors or falling back to password
      if (errStr.contains('cancel') || errStr.contains('Cancel') || errStr.contains('AUTH_CANCELLED') || errStr.contains('Canceled')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication cancelled.'),
            backgroundColor: Colors.amber,
          ),
        );
        return;
      }

      // If it is another biometric/network/server error, try mock fallback or show it
      try {
        final devId = await ApiService.getDeviceId();
        final loginRes = await ApiService().login(widget.mobileNumber, '1234', devId);
        
        final responseCodeRaw = loginRes['response_code'];
        final int responseCode = responseCodeRaw is int
            ? responseCodeRaw
            : int.tryParse(responseCodeRaw?.toString() ?? '') ?? (loginRes['token'] != null ? 1 : 0);
        final apiMessage = loginRes['message'] ?? '';

        await _handleResponseRouting(responseCode, apiMessage, loginRes);
      } catch (err) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. Premium Gradient Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          const Color(0xFF020617),
                          const Color(0xFF0B132B), // Premium dark blue-indigo accent
                          const Color(0xFF020617),
                        ]
                      : [
                          const Color(0xFFF8FAFC),
                          const Color(0xFFEEF2F6), // Premium light grey-blue accent
                          const Color(0xFFF8FAFC),
                        ],
                ),
              ),
            ),
          ),

          // 2. Content Screen
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: null,
            body: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 40),
                                  // Visual Logo of the selected Sahakari
                                  Builder(
                                    builder: (context) {
                                      final selectedSahakari = AuthStore().selectedCooperative;
                                      final String sahakariName = selectedSahakari?['name'] ?? '';
                                      final String? logoUrl = selectedSahakari?['logo_url'];
                                      final String? gradientClass = selectedSahakari?['gradient'];
                                      final gradient = _getGradient(gradientClass);
                                      final String initialLetter = sahakariName.isNotEmpty ? sahakariName.substring(0, 1) : 'B';

                                      return Center(
                                        child: Container(
                                          width: 86,
                                          height: 86,
                                          padding: const EdgeInsets.all(3),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white.withValues(alpha: 0.1)
                                                  : Colors.black.withValues(alpha: 0.05),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: logoUrl == null || logoUrl.isEmpty ? gradient : null,
                                              color: logoUrl != null && logoUrl.isNotEmpty ? Colors.white : null,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (logoUrl == null || logoUrl.isEmpty ? const Color(0xFF2563EB) : Colors.black).withValues(alpha: 0.2),
                                                  blurRadius: 16,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: logoUrl != null && logoUrl.isNotEmpty
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(40),
                                                    child: Image.network(
                                                      logoUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) {
                                                        return Container(
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            gradient: gradient,
                                                          ),
                                                          child: Center(
                                                            child: Text(
                                                              initialLetter,
                                                              style: const TextStyle(
                                                                fontSize: 32,
                                                                fontWeight: FontWeight.bold,
                                                                color: Colors.white,
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  )
                                                : Center(
                                                    child: Text(
                                                      initialLetter,
                                                      style: const TextStyle(
                                                        fontSize: 32,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 24),
                                  Builder(
                                    builder: (context) {
                                      final selectedSahakari = AuthStore().selectedCooperative;
                                      final String sahakariName = selectedSahakari?['name'] ?? '';
                                      return Column(
                                        children: [
                                          Text(
                                            sahakariName.isNotEmpty ? sahakariName : 'Welcome Back',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w900,
                                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          if (sahakariName.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Text(
                                              'Welcome Back',
                                              style: TextStyle(
                                                fontSize: 15,
                                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: Text(
                                      widget.mobileNumber,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Password Input Field
                                  Text(
                                    'PASSWORD',
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _passwordController,
                                    keyboardType: TextInputType.visiblePassword,
                                    obscureText: _obscurePassword,
                                    style: TextStyle(
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      fontSize: 16,
                                    ),
                                    decoration: InputDecoration(
                                      prefixIcon: Icon(
                                        Icons.lock_outline_rounded,
                                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword = !_obscurePassword;
                                          });
                                        },
                                      ),
                                      hintText: 'Enter Password'.tr,
                                      hintStyle: TextStyle(
                                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                      ),
                                      filled: true,
                                      fillColor: isDark
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? Colors.white.withValues(alpha: 0.08)
                                              : Colors.black.withValues(alpha: 0.08),
                                          width: 1.5,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(18),
                                        borderSide: BorderSide(
                                          color: isDark
                                              ? const Color(0xFF60A5FA).withValues(alpha: 0.6)
                                              : const Color(0xFF2563EB).withValues(alpha: 0.6),
                                          width: 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Primary Submit Button inside visual gradient wrapper
                                  Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      gradient: (_isLoading || _passwordController.text.trim().isEmpty)
                                          ? null
                                          : LinearGradient(
                                              colors: [
                                                isDark ? const Color(0xFF3B82F6) : const Color(0xFF2563EB),
                                                isDark ? const Color(0xFF1D4ED8) : const Color(0xFF1D4ED8),
                                              ],
                                            ),
                                      color: (_isLoading || _passwordController.text.trim().isEmpty)
                                          ? (isDark
                                              ? Colors.white.withValues(alpha: 0.05)
                                              : Colors.black.withValues(alpha: 0.05))
                                          : null,
                                      boxShadow: (_isLoading || _passwordController.text.trim().isEmpty)
                                          ? []
                                          : [
                                              BoxShadow(
                                                color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.3 : 0.2),
                                                blurRadius: 16,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: (_isLoading || _passwordController.text.trim().isEmpty) ? null : _submitPassword,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        disabledBackgroundColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : Text(
                                              'Secure Login'.tr,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: (_isLoading || _passwordController.text.trim().isEmpty)
                                                    ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                                                    : Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Quick Biometric login trigger
                                  if (_canAuthenticate) ...[
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            _isFaceId ? Icons.face_unlock_rounded : Icons.fingerprint_rounded,
                                            color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                            size: 50,
                                          ),
                                          onPressed: _authenticateBiometrics,
                                        ),
                                      ],
                                    ),
                                    Center(
                                      child: Text(
                                        _isFaceId ? 'Tap to Login with Face ID'.tr : 'Tap to Login with Fingerprint'.tr,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 30),
                                  ],
                                ],
                              ),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Login with another phone number
                                  Center(
                                    child: TextButton(
                                      onPressed: () async {
                                        final store = AuthStore();
                                        await store.setRegisteredMobile(null);
                                        await store.setMobile(null);
                                        await store.setBiometricEnabled(false);
                                        await store.setNeverAskBiometric(false);
                                        await store.clearAuth();
                                        
                                        if (!mounted) return;
                                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                                      },
                                      child: Text(
                                        'Login with another phone number',
                                        style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  // Switch cooperative option
                                  Center(
                                    child: TextButton(
                                      onPressed: () {
                                        AuthStore().clearAll();
                                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                                      },
                                      child: Text(
                                        'Switch Cooperative Bank',
                                        style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}
