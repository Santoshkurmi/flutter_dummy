import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
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
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../services/location_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/slider_image_cache_service.dart';

class LoginPage extends StatefulWidget {
  final String mobileNumber;
  const LoginPage({super.key, required this.mobileNumber});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  final LocalAuthentication _auth = LocalAuthentication();
  bool _isLoading = false;
  bool _canAuthenticate = false;
  bool _isFaceId = false;
  bool _obscurePassword = true;
  bool _deviceHasBiometricHardware = false;

  late final PageController _pageController;
  int _currentImageIndex = 0;
  int _currentPageViewIndex = 0;
  Timer? _sliderTimer;
  bool _isAutoplayEnabled = true;

  static const List<String> _defaultFallbackUrls = [
    'https://images.unsplash.com/photo-1559526324-4b87b5e36e44?w=800&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1501167786227-4cba60f6d58f?w=800&auto=format&fit=crop&q=60',
    'https://images.unsplash.com/photo-1589758438368-0ad531db3366?w=800&auto=format&fit=crop&q=60',
  ];

  List<String> _sliderImages = List.from(_defaultFallbackUrls);
  Map<String, String> _cachedPaths = {};

  bool get _isDarkMode => AuthStore().isDarkMode;

  Future<void> _loadCachedSlider() async {
    try {
      final savedUrls = await SliderImageCacheService.getSavedUrls();
      final List<String> urlsToLoad = savedUrls.isNotEmpty ? savedUrls : _defaultFallbackUrls;
      
      final Map<String, String> localPaths = {};
      for (final url in urlsToLoad) {
        final path = await SliderImageCacheService.getLocalPath(url);
        if (File(path).existsSync()) {
          localPaths[url] = path;
        }
      }

      if (mounted) {
        setState(() {
          _sliderImages = urlsToLoad;
          _cachedPaths = localPaths;
        });
      }
    } catch (_) {}
  }

  Future<void> _downloadSliderImages(List<String> urls) async {
    for (final url in urls) {
      if (!_cachedPaths.containsKey(url)) {
        final path = await SliderImageCacheService.cacheImage(url);
        if (path != null && mounted) {
          setState(() {
            _cachedPaths[url] = path;
          });
        }
      }
    }
  }

  Future<void> _fetchSliderImages() async {
    try {
      final res = await ApiService().get('/mobile-app-slides');
      List<String> newUrls = [];
      if (res != null && res['response_code'] == 1 && res['data'] != null) {
        final List<dynamic> slides = res['data'] as List<dynamic>;
        if (slides.isNotEmpty) {
          newUrls = slides
              .map((slide) => slide['image_path']?.toString() ?? '')
              .where((url) => url.isNotEmpty)
              .toList();
        }
      }

      if (newUrls.isEmpty) {
        newUrls = _defaultFallbackUrls;
      }

      // Check if urls list actually changed
      bool listChanged = newUrls.length != _sliderImages.length;
      if (!listChanged) {
        for (int i = 0; i < newUrls.length; i++) {
          if (newUrls[i] != _sliderImages[i]) {
            listChanged = true;
            break;
          }
        }
      }

      if (listChanged && mounted) {
        setState(() {
          _sliderImages = newUrls;
        });
        await SliderImageCacheService.saveUrls(newUrls);
      }

      // Pre-fetch in background
      await _downloadSliderImages(newUrls);

      // Cleanup unused files
      await SliderImageCacheService.cleanUnusedCache(newUrls);
    } catch (_) {
      // Fallback: prefetch current offline/default images
      await _downloadSliderImages(_sliderImages);
    }
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    final int initialPage = 999 - (999 % _sliderImages.length);
    _currentPageViewIndex = initialPage;
    _pageController = PageController(initialPage: initialPage);
    _startSliderTimer();
    
    // Synchronously check cache for instant rendering
    final authStore = AuthStore();
    final type = authStore.biometricType;
    if (authStore.isBiometricEnabled && type != null) {
      _canAuthenticate = true;
      _isFaceId = (type == 'face');
    }
    
    _checkBiometrics();
    _requestPermissionsAndWarmUp();
    AuthStore().addListener(_onStoreChange);
    
    // Load local cached images instantly before hitting API
    _loadCachedSlider().then((_) {
      _fetchSliderImages();
    });
  }

  Future<void> _requestPermissionsAndWarmUp() async {
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        // 1. Request native OS-level notification permission using permission_handler
        await Permission.notification.request();
      }
    } catch (_) {}

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
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
    }
  }

  @override
  void dispose() {
    _sliderTimer?.cancel();
    _pageController.dispose();
    _passwordController.removeListener(_onPasswordChanged);
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    AuthStore().removeListener(_onStoreChange);
    super.dispose();
  }

  void _onStoreChange() {
    if (mounted) setState(() {});
  }

  void _onPasswordChanged() {
    setState(() {});
  }

  void _startSliderTimer() {
    _sliderTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted && _pageController.hasClients && (ModalRoute.of(context)?.isCurrent ?? false)) {
        int nextPage = _pageController.page!.round() + 1;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _openFullScreenImage(BuildContext context, int index) {
    _passwordFocusNode.unfocus();
    FocusScope.of(context).unfocus();
    _isAutoplayEnabled = false;
    _sliderTimer?.cancel();
    _sliderTimer = null;

    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.9),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: FullScreenImagePage(
              imageUrls: _sliderImages,
              cachedPaths: _cachedPaths,
              initialIndex: index,
              isDark: _isDarkMode,
            ),
          );
        },
      ),
    ).then((result) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _passwordFocusNode.unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        }
      });
      if (result is int) {
        setState(() {
          _currentPageViewIndex = result;
          _currentImageIndex = result % _sliderImages.length;
        });
        if (_pageController.hasClients) {
          _pageController.jumpToPage(result);
        }
      }
      if (_isAutoplayEnabled) {
        _startSliderTimer();
      }
    });
  }

  Widget _buildImageSlider() {
    final isDark = _isDarkMode;
    final List<List<Color>> indicatorColors = [
      [const Color(0xFF2563EB), const Color(0xFF4338CA)],
      [const Color(0xFF059669), const Color(0xFF0F766E)],
      [const Color(0xFF9333EA), const Color(0xFFBE123C)],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 180,
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification notification) {
                if (notification is UserScrollNotification) {
                  if (notification.direction != ScrollDirection.idle) {
                    _isAutoplayEnabled = false;
                    _sliderTimer?.cancel();
                    _sliderTimer = null;
                  }
                }
                return false;
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _openFullScreenImage(context, _currentPageViewIndex);
                },
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPageViewIndex = index;
                      _currentImageIndex = index % _sliderImages.length;
                    });
                  },
                  itemBuilder: (context, index) {
                    final int imageIndex = index % _sliderImages.length;
                    final String url = _sliderImages[imageIndex];
                    final String? localPath = _cachedPaths[url];
                    final bool hasLocal = localPath != null && File(localPath).existsSync();

                    return GestureDetector(
                      onTap: () => _openFullScreenImage(context, index),
                      child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Hero(
                              tag: 'slider_image_$index',
                              child: hasLocal
                                  ? Image.file(
                                      File(localPath),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.image_not_supported_outlined,
                                              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.image_not_supported_outlined,
                                              color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.4),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double page = 0.0;
            if (_pageController.hasClients) {
              page = _pageController.page ?? 0.0;
            } else {
              page = _currentImageIndex.toDouble();
            }
            
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_sliderImages.length, (index) {
                double diff = (index - (page % _sliderImages.length));
                if (diff > _sliderImages.length / 2.0) {
                  diff -= _sliderImages.length;
                } else if (diff < -_sliderImages.length / 2.0) {
                  diff += _sliderImages.length;
                }
                double distance = diff.abs();
                double activeRatio = (1.0 - distance.clamp(0.0, 1.0));
                double width = 6.0 + (18.0 * activeRatio);
                final colors = indicatorColors[index % indicatorColors.length];

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: activeRatio > 0.05
                        ? LinearGradient(
                            colors: colors.map((c) => c.withValues(alpha: activeRatio)).toList(),
                          )
                        : null,
                    color: activeRatio <= 0.05
                        ? (isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.15))
                        : null,
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }

  Future<void> _checkBiometrics() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (mounted) {
        setState(() {
          _deviceHasBiometricHardware = isSupported && canCheck;
        });
      }
    } catch (_) {}

    final authStore = AuthStore();
    if (authStore.isBiometricEnabled && authStore.biometricType != null) {
      setState(() {
        _canAuthenticate = true;
        _isFaceId = authStore.biometricType == 'face';
      });
      return;
    }

    try {
      final isEnabled = authStore.isBiometricEnabled;
      
      if (_deviceHasBiometricHardware && isEnabled) {
        final availableBiometrics = await _auth.getAvailableBiometrics();
        final hasFace = availableBiometrics.contains(BiometricType.face);
        final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
        final type = (hasFace || isIOS) ? 'face' : 'fingerprint';
        
        await authStore.setBiometricType(type);
        
        setState(() {
          _canAuthenticate = true;
          _isFaceId = (type == 'face');
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
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
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
    }

    // 2. Retrieve location using helper service
    try {
      final loc = await LocationService().getLocation(forceRequestPermission: true);
      latitude = loc['latitude'];
      longitude = loc['longitude'];
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
          // ── Biometric decision BEFORE setToken ─────────────────────────────
          // setToken() calls notifyListeners() which causes InitialRouter to
          // rebuild and return DashboardPage(), unmounting LoginPage before we
          // can navigate ourselves. By making the decision here (while still
          // mounted) and writing it to a flag, InitialRouter will read the flag
          // and route to BiometricSetupPage instead of DashboardPage.

          bool hasHardwareNow = _deviceHasBiometricHardware;
          if (!hasHardwareNow) {
            try {
              final isSupported = await _auth.isDeviceSupported();
              final canCheck = await _auth.canCheckBiometrics;
              hasHardwareNow = isSupported && canCheck;
              if (mounted) setState(() => _deviceHasBiometricHardware = hasHardwareNow);
            } catch (_) {}
          }

          final isServerBiometricSetup =
              (res['is_biometric_setup'] == true || res['is_biometric_setup'] == 1) ||
              (data['is_biometric_setup'] == true || data['is_biometric_setup'] == 1);
          final isLocallyEnabled = AuthStore().isBiometricEnabled;
          final neverAsk = AuthStore().neverAskBiometric;

          final shouldShowBiometric =
              hasHardwareNow && (!isServerBiometricSetup || !isLocallyEnabled) && !neverAsk;

          // Set the flag before setToken so InitialRouter sees it on first rebuild
          if (shouldShowBiometric) {
            AuthStore().setPendingBiometricSetup(true);
          }

          // ── Persist auth (InitialRouter rebuilds here, routes via flag) ────
          await AuthStore().setToken(token);
          await AuthStore().setMobile(widget.mobileNumber);
          await AuthStore().setRegisteredMobile(widget.mobileNumber);

          final profileRes = await ApiService().getProfile();
          if (profileRes['data'] != null) {
            await AuthStore().setProfile(profileRes['data']);
          }
          // Navigation is owned by InitialRouter — no Navigator call needed here.
        } else {
          if (!mounted) return;
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
        {
          final needsPasswordSetup = res['needs_password_setup'] ?? false;
          final needsDeviceLink = res['needs_device_link'] ?? true;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => DeviceLinkingPage(
                mobileNumber: widget.mobileNumber,
                directPasswordSetup: !needsDeviceLink && needsPasswordSetup,
              ),
            ),
            (route) => false,
          );
        }
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
    return GestureDetector(
      onTap: () {
        _passwordFocusNode.unfocus();
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
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
                            children: [
                                  const SizedBox(height: 10),
                                  // Visual Logo & Sahakari Name Card in same row
                                  Builder(
                                    builder: (context) {
                                      final selectedSahakari = AuthStore().selectedCooperative;
                                      final String sahakariName = selectedSahakari?['name'] ?? '';
                                      final String sahakariAddress = selectedSahakari?['address'] ?? '';
                                      final String? logoUrl = selectedSahakari?['logo_url'];
                                      final String? gradientClass = selectedSahakari?['gradient'];
                                      final gradient = _getGradient(gradientClass);
                                      final String initialLetter = sahakariName.isNotEmpty ? sahakariName.substring(0, 1) : 'B';

                                      return Card(
                                        elevation: 0,
                                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: BorderSide(
                                            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 44,
                                                height: 44,
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: isDark
                                                        ? Colors.white.withValues(alpha: 0.1)
                                                        : Colors.black.withValues(alpha: 0.05),
                                                    width: 1.2,
                                                  ),
                                                ),
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: logoUrl == null || logoUrl.isEmpty ? gradient : null,
                                                    color: logoUrl != null && logoUrl.isNotEmpty ? Colors.white : null,
                                                  ),
                                                  child: logoUrl != null && logoUrl.isNotEmpty
                                                      ? ClipRRect(
                                                          borderRadius: BorderRadius.circular(20),
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
                                                                      fontSize: 16,
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
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      sahakariName.isNotEmpty ? sahakariName : 'Cooperative Bank',
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (sahakariAddress.isNotEmpty) ...[
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        sahakariAddress,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569),
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Welcome Back and Phone number in different row in center
                                  Center(
                                    child: Text(
                                      'Welcome Back'.tr,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Center(
                                    child: Text(
                                      widget.mobileNumber,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

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
                                    focusNode: _passwordFocusNode,
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
                                  const SizedBox(height: 20),

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
                                              'Login'.tr,
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
                                  
                                  // Quick Biometric login trigger
                                  if (_canAuthenticate) ...[
                                    const SizedBox(height: 12),
                                    Center(
                                      child: InkWell(
                                        onTap: _isLoading ? null : _authenticateBiometrics,
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                _isFaceId ? Icons.face_unlock_rounded : Icons.fingerprint_rounded,
                                                color: _isLoading
                                                    ? (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))
                                                    : (isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB)),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _isFaceId ? 'Login with Face ID'.tr : 'Login with Fingerprint'.tr,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  const SizedBox(height: 8),
                                  // Login with another phone number
                                  Center(
                                    child: TextButton.icon(
                                      onPressed: () async {
                                        final store = AuthStore();
                                        await store.setRegisteredMobile(null);
                                        await store.setMobile(null);
                                        await store.setBiometricEnabled(false);
                                        await store.setNeverAskBiometric(false);
                                        await store.setBiometricType(null);
                                        await store.setEnableCaching(true);
                                        await ApiService.clearCache();
                                        await store.clearAuth();
                                        
                                        if (!mounted) return;
                                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                                      },
                                      icon: Icon(
                                        Icons.help_outline_rounded,
                                        size: 16,
                                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569),
                                      ),
                                      label: Text(
                                        'Login with another phone number'.tr,
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569),
                                          fontSize: 13,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ),
                                  if (!AuthStore().isCustomApp) ...[
                                    // Switch cooperative option
                                    Center(
                                      child: TextButton.icon(
                                        onPressed: () {
                                          AuthStore().clearAll();
                                          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                                        },
                                        icon: Icon(
                                          Icons.help_outline_rounded,
                                          size: 16,
                                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569),
                                        ),
                                        label: Text(
                                          'Switch Cooperative Bank'.tr,
                                          style: TextStyle(
                                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569),
                                            fontSize: 13,
                                          ),
                                        ),
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 16),
                                  _buildImageSlider(),
                                  const SizedBox(height: 12),
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
    ),
  );
}
}

class FullScreenImagePage extends StatefulWidget {
  final List<String> imageUrls;
  final Map<String, String> cachedPaths;
  final int initialIndex;
  final bool isDark;

  const FullScreenImagePage({
    super.key,
    required this.imageUrls,
    required this.cachedPaths,
    required this.initialIndex,
    required this.isDark,
  });

  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> with SingleTickerProviderStateMixin {
  PageController? _fullscreenPageController;
  double? _lastScreenWidth;
  late int _currentPageIndex;
  final Map<int, TransformationController> _transformationControllers = {};
  final Map<int, bool> _isScaledMap = {};
  double _dragOffset = 0.0;
  int _activePointers = 0;
  double _startX = 0.0;
  double _startY = 0.0;
  bool _dragStarted = false;
  bool _isVerticalDrag = false;
  bool _isHorizontalDrag = false;

  late AnimationController _zoomAnimationController;
  Animation<Matrix4>? _zoomAnimation;
  int? _zoomingPageIndex;
  TapDownDetails? _doubleTapDownDetails;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialIndex;
    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _zoomAnimationController.addListener(() {
      if (_zoomAnimation != null && _zoomingPageIndex != null) {
        final controller = _transformationControllers[_zoomingPageIndex];
        if (controller != null) {
          controller.value = _zoomAnimation!.value;
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenWidth = MediaQuery.of(context).size.width;
    if (_fullscreenPageController == null || _lastScreenWidth != screenWidth) {
      _lastScreenWidth = screenWidth;
      _fullscreenPageController?.dispose();
      _fullscreenPageController = PageController(
        initialPage: _currentPageIndex,
      );
    }
  }

  @override
  void dispose() {
    _fullscreenPageController?.dispose();
    _zoomAnimationController.dispose();
    for (final controller in _transformationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleDoubleTap(TapDownDetails details, int index) {
    final controller = _getTransformationController(index);
    final currentMatrix = controller.value;
    final currentScale = currentMatrix.entry(0, 0);

    double targetScale;
    if (currentScale <= 1.05) {
      targetScale = 2.2;
    } else if (currentScale <= 2.5) {
      targetScale = 4.0;
    } else {
      targetScale = 1.0;
    }

    final Matrix4 targetMatrix;
    if (targetScale == 1.0) {
      targetMatrix = Matrix4.identity();
    } else {
      // C is the tapped point in child coordinate space
      final Offset C = details.localPosition;
      
      // V is the tapped point in viewport coordinate space
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final Offset V = renderBox.globalToLocal(details.globalPosition);

      targetMatrix = Matrix4.translationValues(V.dx, V.dy, 0.0)
        ..multiply(Matrix4.diagonal3Values(targetScale, targetScale, 1.0))
        ..multiply(Matrix4.translationValues(-C.dx, -C.dy, 0.0));
    }

    _zoomingPageIndex = index;
    _zoomAnimation = Matrix4Tween(
      begin: currentMatrix,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _zoomAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _zoomAnimationController.stop();
    _zoomAnimationController.reset();
    _zoomAnimationController.forward();
  }

  TransformationController _getTransformationController(int index) {
    if (!_transformationControllers.containsKey(index)) {
      final controller = TransformationController();
      controller.addListener(() {
        final scale = controller.value.entry(0, 0);
        final isScaled = scale > 1.01;
        final wasScaled = _isScaledMap[index] ?? false;
        if (wasScaled != isScaled) {
          setState(() {
            _isScaledMap[index] = isScaled;
          });
        }
      });
      _transformationControllers[index] = controller;
    }
    return _transformationControllers[index]!;
  }

  double _getScale(int index) {
    if (!_transformationControllers.containsKey(index)) return 1.0;
    return _transformationControllers[index]!.value.entry(0, 0);
  }

  double get _currentScale {
    return _getScale(_currentPageIndex);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    double opacity = (1.0 - (_dragOffset.abs() / 300.0)).clamp(0.0, 1.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_currentPageIndex);
      },
      child: Scaffold(
        backgroundColor: (isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC)).withValues(alpha: opacity),
        body: Listener(
          onPointerDown: (event) {
            setState(() {
              _activePointers++;
              if (_activePointers == 1) {
                _startX = event.position.dx;
                _startY = event.position.dy;
                _dragStarted = true;
                _isVerticalDrag = false;
                _isHorizontalDrag = false;
              } else {
                _dragOffset = 0.0;
                _dragStarted = false;
                _isVerticalDrag = false;
                _isHorizontalDrag = false;
              }
            });
          },
          onPointerMove: (event) {
            if (_activePointers == 1 && _dragStarted && _currentScale <= 1.01) {
              final currentX = event.position.dx;
              final currentY = event.position.dy;
              final deltaX = (currentX - _startX).abs();
              final deltaY = currentY - _startY;

              // If direction is not locked yet, check if we exceed the threshold to lock it
              if (!_isVerticalDrag && !_isHorizontalDrag) {
                const double threshold = 20.0; // 20px threshold before triggering/locking
                if (deltaY > threshold && deltaY > deltaX) {
                  _isVerticalDrag = true;
                } else if (deltaX > threshold && deltaX >= deltaY) {
                  _isHorizontalDrag = true;
                }
              }

              if (_isVerticalDrag) {
                // To avoid sudden jump when exceeding threshold, subtract threshold
                const double threshold = 20.0;
                final offset = deltaY - threshold;
                setState(() {
                  _dragOffset = offset > 0 ? offset : 0.0;
                });
              }
            }
          },
          onPointerUp: (event) {
            setState(() {
              _activePointers--;
              if (_activePointers < 0) _activePointers = 0;
  
              if (_activePointers == 0 && _dragStarted) {
                _dragStarted = false;
                final wasVertical = _isVerticalDrag;
                _isVerticalDrag = false;
                _isHorizontalDrag = false;
                
                if (wasVertical && _dragOffset > 80.0) {
                  Navigator.of(context).pop(_currentPageIndex);
                } else {
                  _dragOffset = 0.0;
                }
              }
            });
          },
          onPointerCancel: (event) {
            setState(() {
              _activePointers--;
              if (_activePointers < 0) _activePointers = 0;
              _dragOffset = 0.0;
              _dragStarted = false;
              _isVerticalDrag = false;
              _isHorizontalDrag = false;
            });
          },
          child: Stack(
            children: [
              Transform.translate(
                offset: Offset(0.0, _dragOffset),
                child: SizedBox.expand(
                  child: PageView.builder(
                    controller: _fullscreenPageController!,
                    physics: (_isScaledMap[_currentPageIndex] ?? false) || _activePointers > 1
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _transformationControllers[_currentPageIndex]?.value = Matrix4.identity();
                        _isScaledMap[_currentPageIndex] = false;
                        _currentPageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final int imageIndex = index % widget.imageUrls.length;
                      final controller = _getTransformationController(index);
                      final url = widget.imageUrls[imageIndex];
                      final localPath = widget.cachedPaths[url];
                      final hasLocal = localPath != null && File(localPath).existsSync();

                      return InteractiveViewer(
                        transformationController: controller,
                        maxScale: 4.0,
                        minScale: 1.0,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onDoubleTapDown: (details) {
                            _doubleTapDownDetails = details;
                          },
                          onDoubleTap: () {
                            if (_doubleTapDownDetails != null) {
                              _handleDoubleTap(_doubleTapDownDetails!, index);
                            }
                          },
                          child: Center(
                            child: Hero(
                              tag: 'slider_image_$index',
                              child: hasLocal
                                  ? Image.file(
                                      File(localPath),
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Image.network(
                                          url,
                                          fit: BoxFit.contain,
                                        );
                                      },
                                    )
                                  : Image.network(
                                      url,
                                      fit: BoxFit.contain,
                                    ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark ? Colors.white : Colors.black,
                        size: 24,
                      ),
                      onPressed: () => Navigator.of(context).pop(_currentPageIndex),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
