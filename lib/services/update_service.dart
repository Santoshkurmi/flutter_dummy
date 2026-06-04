import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:ui';

class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  static const String _keyLastCheckTime = 'update_last_check_time';
  static const String _keyLastFoundVersion = 'update_last_found_version';
  static const String _keyShowCountPrefix = 'update_show_count_';
  static const String _keyCachedNotes = 'update_cached_notes';
  static const String _keyCachedUrl = 'update_cached_url';

  bool _isChecking = false;

  /// Triggered at app startup. Runs asynchronously in the background.
  Future<void> checkForUpdates(BuildContext context) async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 1. Clean up stale/old cache if current version matches or exceeds last found update version
      final lastFoundVersion = prefs.getString(_keyLastFoundVersion);
      if (lastFoundVersion != null) {
        if (!_isVersionOlder(currentVersion, lastFoundVersion)) {
          await prefs.remove(_keyLastFoundVersion);
          await prefs.remove(_keyCachedNotes);
          await prefs.remove(_keyCachedUrl);
          await prefs.remove('$_keyShowCountPrefix$lastFoundVersion');
        }
      }

      // 2. Read latest cache state
      final cachedVersion = prefs.getString(_keyLastFoundVersion);
      final cachedShowCountKey = cachedVersion != null ? '$_keyShowCountPrefix$cachedVersion' : null;
      final cachedShowCount = cachedShowCountKey != null ? (prefs.getInt(cachedShowCountKey) ?? 0) : 0;

      // 3. If cached version is newer AND show count < 5, show it immediately (skip network)
      if (cachedVersion != null && _isVersionOlder(currentVersion, cachedVersion) && cachedShowCount < 5) {
        final notes = prefs.getString(_keyCachedNotes) ?? 'New version available.';
        final url = prefs.getString(_keyCachedUrl) ?? '';
        
        await prefs.setInt(cachedShowCountKey!, cachedShowCount + 1);
        _isChecking = false;
        
        if (context.mounted) {
          _showUpdateDialog(
            context: context,
            currentVersion: currentVersion,
            latestVersion: cachedVersion,
            releaseNotes: notes,
            updateUrl: url,
            inAppUpdateSupported: Platform.isAndroid,
          );
        }
        return;
      }

      // 4. Check if 2-hour network throttling window has elapsed
      final lastCheckTimeMs = prefs.getInt(_keyLastCheckTime) ?? 0;
      final currentTimeMs = DateTime.now().millisecondsSinceEpoch;
      final timeDifferenceHours = (currentTimeMs - lastCheckTimeMs) / (1000 * 60 * 60);

      if (timeDifferenceHours < 2) {
        _isChecking = false;
        return; // Throttled
      }

      // 5. Update last check timestamp
      await prefs.setInt(_keyLastCheckTime, currentTimeMs);

      // 6. Perform the actual Network Check
      String latestVersion = '';
      String releaseNotes = '';
      String updateUrl = '';
      AppUpdateInfo? androidUpdateInfo;

      if (Platform.isAndroid) {
        try {
          androidUpdateInfo = await InAppUpdate.checkForUpdate();
          if (androidUpdateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
            latestVersion = androidUpdateInfo.availableVersionCode.toString();
            releaseNotes = 'A new release is ready on Google Play Store.';
            updateUrl = 'market://details?id=${packageInfo.packageName}';
          }
        } catch (e) {
          debugPrint('Google Play In-App Update API not available: $e');
        }
      } else if (Platform.isIOS) {
        // Query iOS App Store Lookup API
        final appleId = dotenv.env['APPLE_APP_ID'] ?? '1234567890';
        final bundleId = packageInfo.packageName;
        
        // Try bundle ID lookup first
        var response = await http.get(Uri.parse('https://itunes.apple.com/lookup?bundleId=$bundleId')).timeout(const Duration(seconds: 5));
        var data = jsonDecode(response.body);
        
        if (data['resultCount'] == 0) {
          // Fallback to Apple App ID lookup
          response = await http.get(Uri.parse('https://itunes.apple.com/lookup?id=$appleId')).timeout(const Duration(seconds: 5));
          data = jsonDecode(response.body);
        }

        if (data['resultCount'] > 0) {
          final result = data['results'][0];
          latestVersion = result['version'] ?? '';
          releaseNotes = result['releaseNotes'] ?? 'Latest version available with stability improvements.';
          updateUrl = result['trackViewUrl'] ?? 'https://apps.apple.com/app/id$appleId';
        }
      }

      // 7. If update found, store details in cache, reset counter to 1, and show dialog
      if (latestVersion.isNotEmpty && _isVersionOlder(currentVersion, latestVersion)) {
        await prefs.setString(_keyLastFoundVersion, latestVersion);
        await prefs.setString(_keyCachedNotes, releaseNotes);
        await prefs.setString(_keyCachedUrl, updateUrl);
        
        final newShowCountKey = '$_keyShowCountPrefix$latestVersion';
        await prefs.setInt(newShowCountKey, 1);

        _isChecking = false;
        if (context.mounted) {
          _showUpdateDialog(
            context: context,
            currentVersion: currentVersion,
            latestVersion: latestVersion,
            releaseNotes: releaseNotes,
            updateUrl: updateUrl,
            inAppUpdateSupported: Platform.isAndroid,
            androidUpdateInfo: androidUpdateInfo,
          );
        }
        return;
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    } finally {
      _isChecking = false;
    }
  }

  /// Compares semantic versions (e.g. 1.0.0 vs 1.0.1)
  bool _isVersionOlder(String current, String latest) {
    try {
      // Split off build number suffixes (+1 etc)
      final currentClean = current.split('+')[0];
      final latestClean = latest.split('+')[0];

      final currentParts = currentClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final latestParts = latestClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLength = latestParts.length > currentParts.length ? latestParts.length : currentParts.length;

      for (var i = 0; i < maxLength; i++) {
        final currentVal = i < currentParts.length ? currentParts[i] : 0;
        final latestVal = i < latestParts.length ? latestParts[i] : 0;

        if (latestVal > currentVal) {
          return true;
        } else if (latestVal < currentVal) {
          return false;
        }
      }
    } catch (_) {}
    return false;
  }

  /// Launch store link via url_launcher
  Future<void> _launchStoreUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch update URL: $url');
    }
  }

  /// Displays the premium glassmorphism custom update dialog
  void _showUpdateDialog({
    required BuildContext context,
    required String currentVersion,
    required String latestVersion,
    required String releaseNotes,
    required String updateUrl,
    required bool inAppUpdateSupported,
    AppUpdateInfo? androidUpdateInfo,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Update Dialog',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        final scale = Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
        );
        final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: anim1, curve: Curves.easeOut),
        );

        return FadeTransition(
          opacity: opacity,
          child: ScaleTransition(
            scale: scale,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 340),
                  decoration: BoxDecoration(
                    color: isDark 
                        ? const Color(0xFF0F172A).withValues(alpha: 0.88) 
                        : Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.08) 
                          : Colors.black.withValues(alpha: 0.06),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      )
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Icon top header
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                            ),
                            child: const Icon(
                              Icons.system_update_rounded,
                              color: Color(0xFF2563EB),
                              size: 38,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        
                        const Text(
                          'Update Available',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        
                        Text(
                          'Version $latestVersion is available. (Local: $currentVersion)',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Release Notes Box
                        const Text(
                          'WHAT\'S NEW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 110),
                          decoration: BoxDecoration(
                            color: isDark 
                                ? Colors.white.withValues(alpha: 0.03) 
                                : Colors.black.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark 
                                  ? Colors.white.withValues(alpha: 0.04) 
                                  : Colors.black.withValues(alpha: 0.04),
                            ),
                          ),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(14.0),
                            child: Text(
                              releaseNotes,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                height: 1.45,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Action Buttons
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Primary Action: Update Now
                            Container(
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  if (Platform.isAndroid && androidUpdateInfo != null) {
                                    try {
                                      await InAppUpdate.performImmediateUpdate();
                                    } catch (_) {
                                      _launchStoreUrl(updateUrl);
                                    }
                                  } else {
                                    _launchStoreUrl(updateUrl);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Update Now',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            
                            // 2. Secondary Action: Background flexible download (Android only)
                            if (Platform.isAndroid && androidUpdateInfo != null) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    try {
                                      final result = await InAppUpdate.startFlexibleUpdate();
                                      if (result == AppUpdateResult.success) {
                                        await InAppUpdate.completeFlexibleUpdate();
                                      }
                                    } catch (e) {
                                      debugPrint('Flexible background update failed: $e');
                                    }
                                  },
                                  icon: const Icon(Icons.downloading_rounded, size: 18),
                                  label: const Text(
                                    'Update in Background',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF2563EB),
                                    side: BorderSide(
                                      color: const Color(0xFF2563EB).withValues(alpha: 0.5),
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            
                            // 3. Later Dismiss Action
                            SizedBox(
                              height: 44,
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF64748B),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Later',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
