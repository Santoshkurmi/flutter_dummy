import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../store/auth_store.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  double? _cachedLatitude;
  double? _cachedLongitude;
  DateTime? _lastFetchTime;

  double? get cachedLatitude => _cachedLatitude;
  double? get cachedLongitude => _cachedLongitude;

  /// Loads cached location from SharedPreferences on app startup.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedLatitude = prefs.getDouble('loc_lat');
      _cachedLongitude = prefs.getDouble('loc_lon');
      final timeStr = prefs.getString('loc_time');
      if (timeStr != null) {
        _lastFetchTime = DateTime.parse(timeStr);
      }
    } catch (_) {}
  }

  /// Checks if cached location exists and is less than 20 minutes old.
  bool isCacheValid() {
    if (_cachedLatitude == null || _cachedLongitude == null || _lastFetchTime == null) {
      return false;
    }
    final difference = DateTime.now().difference(_lastFetchTime!);
    return difference.inMinutes < 20;
  }

  /// Safely fetches the location in the background with High accuracy and 20s timeout.
  /// If [forceRequestPermission] is true, it will request permission.
  /// If false, it only checks if permission is already granted.
  Future<Position?> fetchLocation({bool forceRequestPermission = false}) async {
    try {
   
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && forceRequestPermission) {
        permission = await Geolocator.requestPermission();
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;


      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 20),
          ),
        );
        
        // Cache globally in memory
        _cachedLatitude = position.latitude;
        _cachedLongitude = position.longitude;
        _lastFetchTime = DateTime.now();

        // Persist to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('loc_lat', position.latitude);
        await prefs.setDouble('loc_lon', position.longitude);
        await prefs.setString('loc_time', _lastFetchTime!.toIso8601String());

        return position;
      }
    } catch (_) {}
    return null;
  }

  /// Call this on app startup. It checks if the cache is valid.
  /// If not, it will try to fetch the location. It will NOT request permission
  /// if not already granted, ensuring zero impact on initial user experience.
  Future<void> refreshLocationOnStartup() async {
    if (isCacheValid()) {
      return;
    }
    await fetchLocation(forceRequestPermission: false);
  }

  /// Returns the cached location if valid. Otherwise, triggers a fetch.
  /// Shows a premium countdown overlay if fetching from hardware during a form action.
  Future<Map<String, String>> getLocation({bool forceRequestPermission = true}) async {
    if (isCacheValid()) {
      return {
        'latitude': _cachedLatitude!.toString(),
        'longitude': _cachedLongitude!.toString(),
      };
    }

    final context = AuthStore.navigatorKey.currentContext;

    // Check if GPS is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled && forceRequestPermission && context != null) {
      final permission = await Geolocator.checkPermission();
      final hasPermission = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      if (hasPermission) {
        if (!context.mounted) {
          // Return stale cache if available, otherwise return empty map
          if (_cachedLatitude != null && _cachedLongitude != null) {
            return {
              'latitude': _cachedLatitude!.toString(),
              'longitude': _cachedLongitude!.toString(),
            };
          }
          return {};
        }
        final gpsEnabled = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const GpsEnableDialog(),
        );
        if (gpsEnabled != true) {
          // Return stale cache if available, otherwise return empty map
          if (_cachedLatitude != null && _cachedLongitude != null) {
            return {
              'latitude': _cachedLatitude!.toString(),
              'longitude': _cachedLongitude!.toString(),
            };
          }
          return {};
        }
      }
    }

    NavigatorState? navigatorState;
    bool dialogShown = false;
    Timer? dialogTimer;

    if (forceRequestPermission && context != null) {
      // Delay showing the dialog by 2 seconds
      dialogTimer = Timer(const Duration(seconds: 2), () {
        if (context.mounted) {
          dialogShown = true;
          navigatorState = Navigator.of(context, rootNavigator: true);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const LocationProgressDialog(maxDurationSeconds: 18),
          );
        }
      });
    }

    try {
      final pos = await fetchLocation(forceRequestPermission: forceRequestPermission);
      if (pos != null) {
        return {
          'latitude': pos.latitude.toString(),
          'longitude': pos.longitude.toString(),
        };
      }
    } finally {
      dialogTimer?.cancel();
      if (dialogShown && navigatorState != null) {
        // Dismiss the dialog safely using pre-captured navigatorState
        navigatorState?.pop();
      }
    }

    // Return stale cache if available, otherwise return empty map
    if (_cachedLatitude != null && _cachedLongitude != null) {
      return {
        'latitude': _cachedLatitude!.toString(),
        'longitude': _cachedLongitude!.toString(),
      };
    }

    return {};
  }
}

class LocationProgressDialog extends StatefulWidget {
  final int maxDurationSeconds;
  const LocationProgressDialog({super.key, this.maxDurationSeconds = 20});

  @override
  State<LocationProgressDialog> createState() => _LocationProgressDialogState();
}

class _LocationProgressDialogState extends State<LocationProgressDialog> {
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.maxDurationSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: CircularProgressIndicator(
                      value: _remainingSeconds / widget.maxDurationSeconds,
                      strokeWidth: 4,
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                    ),
                  ),
                  Text(
                    '$_remainingSeconds',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Acquiring GPS Signal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we determine your location for security validation.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GpsEnableDialog extends StatefulWidget {
  const GpsEnableDialog({super.key});

  @override
  State<GpsEnableDialog> createState() => _GpsEnableDialogState();
}

class _GpsEnableDialogState extends State<GpsEnableDialog> {
  bool _isWaiting = false;
  Timer? _pollingTimer;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    setState(() {
      _isWaiting = true;
    });
    
    // Open settings page
    Geolocator.openLocationSettings();

    // Poll every 1 second
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (enabled) {
        timer.cancel();
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 6.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!_isWaiting) ...[
                // Warning icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_off_rounded,
                    color: Color(0xFFEF4444),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Location Services Off',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'To continue, please enable GPS/location services on your device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _startPolling,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Enable GPS',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Waiting screen
                SizedBox(
                  width: 76,
                  height: 76,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Waiting for GPS...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Please enable location services in your system settings and return to the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
