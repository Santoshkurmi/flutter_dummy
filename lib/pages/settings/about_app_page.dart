import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import '../../services/translation_service.dart';
import '../../store/auth_store.dart';
import 'changelogs_page.dart';

class AppDiagnostics {
  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;
  final String deviceBrand;
  final String deviceModel;
  final String osVersion;
  final String systemRam;
  final String storageSpace;

  AppDiagnostics({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    required this.deviceBrand,
    required this.deviceModel,
    required this.osVersion,
    required this.systemRam,
    required this.storageSpace,
  });
}

class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  int _tapCount = 0;
  late Future<AppDiagnostics> _diagnosticsFuture;
  final GlobalKey _globalKey = GlobalKey();
  bool _isSharing = false;

  @override
  void initState() {
    super.initState();
    _diagnosticsFuture = _loadDiagnostics();
  }

  Future<AppDiagnostics> _loadDiagnostics() async {
    final packageInfo = await PackageInfo.fromPlatform();
    
    String deviceBrand = 'N/A';
    String deviceModel = 'N/A';
    String osVersion = 'N/A';
    String systemRam = 'N/A';
    String storageSpace = 'N/A';

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceBrand = androidInfo.brand;
        deviceModel = androidInfo.model;
        osVersion = 'Android ${androidInfo.version.release}';
        
        // RAM
        final file = File('/proc/meminfo');
        if (await file.exists()) {
          final lines = await file.readAsLines();
          for (final line in lines) {
            if (line.startsWith('MemTotal:')) {
              final parts = line.split(':');
              if (parts.length > 1) {
                final match = RegExp(r'(\d+)').firstMatch(parts[1]);
                if (match != null) {
                  final kb = int.parse(match.group(1)!);
                  final gb = (kb / (1024 * 1024)).round();
                  systemRam = '$gb GB';
                }
              }
            }
          }
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceBrand = 'Apple';
        deviceModel = '${iosInfo.model} (${iosInfo.utsname.machine})';
        osVersion = '${iosInfo.systemName} ${iosInfo.systemVersion}';
      }

      // Storage Space
      final diskSpacePlus = DiskSpacePlus();
      final freeSpace = await diskSpacePlus.getFreeDiskSpace;
      final totalSpace = await diskSpacePlus.getTotalDiskSpace;
      if (freeSpace != null && totalSpace != null) {
        final freeGb = freeSpace / 1024.0;
        final totalGb = totalSpace / 1024.0;
        storageSpace = '${freeGb.toStringAsFixed(1)} GB / ${totalGb.toStringAsFixed(1)} GB';
      }
    } catch (e) {
      // Fallback
    }

    return AppDiagnostics(
      appName: packageInfo.appName,
      packageName: packageInfo.packageName,
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      deviceBrand: deviceBrand,
      deviceModel: deviceModel,
      osVersion: osVersion,
      systemRam: systemRam,
      storageSpace: storageSpace,
    );
  }

  Future<void> _sharePageScreenshot(BuildContext context) async {
    if (_isSharing) return;
    setState(() {
      _isSharing = true;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/about_app_specs.png').create();
      await file.writeAsBytes(pngBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Bright Sahakari App Specifications & Diagnostics'.tr,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share screenshot: $e'.tr)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  String _formatNepaliNumbers(String input) {
    return AuthStore().language == 'ne'
        ? TranslationService.toNepaliNumbers(input)
        : input;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final cardBgColor = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0);
    final accentColor = const Color(0xFF2563EB); // Indigo/Blue accent

    return Stack(
      children: [
        Scaffold(
          backgroundColor: isDarkMode ? const Color(0xFF020617) : Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: primaryTextColor,
                    ),
                    onPressed: () => Navigator.pop(context),
                  )
                : null,
            title: Text(
              'About App'.tr,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: primaryTextColor,
                fontSize: 20,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.share_rounded, color: primaryTextColor),
                onPressed: () => _sharePageScreenshot(context),
              ),
            ],
          ),
          body: SafeArea(
            child: FutureBuilder<AppDiagnostics>(
              future: _diagnosticsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                    ),
                  );
                }

                final diag = snapshot.data;
                final appName = diag?.appName ?? 'Bright Sahakari';
                final packageName = diag?.packageName ?? 'N/A';
                final version = diag?.version ?? 'N/A';
                final buildNumber = diag?.buildNumber ?? 'N/A';

                return RepaintBoundary(
                  key: _globalKey,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    children: [
                      const SizedBox(height: 10),
                      // Specs details card styled like Android About Device
                      Container(
                        decoration: BoxDecoration(
                          color: cardBgColor,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode ? Colors.black.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.01),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            _buildSpecRow(
                              label: 'App Name'.tr,
                              value: appName.tr,
                              icon: Icons.label_important_outline_rounded,
                              accentColor: accentColor,
                              isDarkMode: isDarkMode,
                              primaryTextColor: primaryTextColor,
                              secondaryTextColor: secondaryTextColor,
                            ),
                            _buildDivider(isDarkMode),
                            _buildSpecRow(
                              label: 'Package Name'.tr,
                              value: packageName,
                              icon: Icons.android_rounded,
                              accentColor: accentColor,
                              isDarkMode: isDarkMode,
                              primaryTextColor: primaryTextColor,
                              secondaryTextColor: secondaryTextColor,
                            ),
                            _buildDivider(isDarkMode),
                            // Clickable App Version row for developer mode activation
                            InkWell(
                              onTap: () async {
                                if (AuthStore().isDeveloperMode) return;
                                _tapCount++;
                                if (_tapCount >= 7) {
                                  _showEnableDeveloperModeDialog(context, isDarkMode);
                                  _tapCount = 0; // Reset tap count after dialog triggers
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: _buildSpecRow(
                                label: 'App Version'.tr,
                                value: _formatNepaliNumbers(version),
                                icon: Icons.info_outline_rounded,
                                accentColor: accentColor,
                                isDarkMode: isDarkMode,
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor,
                              ),
                            ),
                            _buildDivider(isDarkMode),
                            _buildSpecRow(
                              label: 'Version Code'.tr,
                              value: _formatNepaliNumbers(buildNumber),
                              icon: Icons.code_rounded,
                              accentColor: accentColor,
                              isDarkMode: isDarkMode,
                              primaryTextColor: primaryTextColor,
                              secondaryTextColor: secondaryTextColor,
                            ),
                            _buildDivider(isDarkMode),
                            _buildSpecRow(
                              label: 'Device Brand'.tr,
                              value: diag?.deviceBrand ?? 'N/A',
                              icon: Icons.branding_watermark_rounded,
                              accentColor: accentColor,
                              isDarkMode: isDarkMode,
                              primaryTextColor: primaryTextColor,
                              secondaryTextColor: secondaryTextColor,
                            ),
                            _buildDivider(isDarkMode),
                            _buildSpecRow(
                              label: 'Device Model'.tr,
                              value: diag?.deviceModel ?? 'N/A',
                              icon: Icons.phone_android_rounded,
                              accentColor: accentColor,
                              isDarkMode: isDarkMode,
                              primaryTextColor: primaryTextColor,
                              secondaryTextColor: secondaryTextColor,
                            ),
                            _buildDivider(isDarkMode),
                            _buildSpecRow(
                              label: 'OS Version'.tr,
                              value: diag?.osVersion ?? 'N/A',
                              icon: Icons.settings_applications_rounded,
                              accentColor: accentColor,
                              isDarkMode: isDarkMode,
                              primaryTextColor: primaryTextColor,
                              secondaryTextColor: secondaryTextColor,
                            ),
                            if (diag?.systemRam != 'N/A') ...[
                              _buildDivider(isDarkMode),
                              _buildSpecRow(
                                label: 'System RAM'.tr,
                                value: _formatNepaliNumbers(diag?.systemRam ?? 'N/A'),
                                icon: Icons.memory_rounded,
                                accentColor: accentColor,
                                isDarkMode: isDarkMode,
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor,
                              ),
                            ],
                            if (diag?.storageSpace != 'N/A') ...[
                              _buildDivider(isDarkMode),
                              _buildSpecRow(
                                label: 'Storage'.tr,
                                value: _formatNepaliNumbers(diag?.storageSpace ?? 'N/A'),
                                icon: Icons.storage_rounded,
                                accentColor: accentColor,
                                isDarkMode: isDarkMode,
                                primaryTextColor: primaryTextColor,
                                secondaryTextColor: secondaryTextColor,
                              ),
                            ],
                            _buildDivider(isDarkMode),
                            _buildClickableSpecRow(
                              context: context,
                              label: 'Changelogs'.tr,
                              icon: Icons.history_rounded,
                              accentColor: accentColor,
                              isDarkMode: isDarkMode,
                              primaryTextColor: primaryTextColor,
                              secondaryTextColor: secondaryTextColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    settings: const RouteSettings(name: 'ChangelogsPage'),
                                    builder: (context) => const ChangelogsPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        if (_isSharing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSpecRow({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
    required bool isDarkMode,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDarkMode ? 0.15 : 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDarkMode ? accentColor.withValues(alpha: 0.8) : accentColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: secondaryTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableSpecRow({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color accentColor,
    required bool isDarkMode,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: isDarkMode ? 0.15 : 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDarkMode ? accentColor.withValues(alpha: 0.8) : accentColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: secondaryTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: secondaryTextColor.withValues(alpha: 0.4),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFEFF6FF),
    );
  }

  void _showEnableDeveloperModeDialog(BuildContext context, bool isDarkMode) {
    final TextEditingController passwordController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security_rounded, color: Color(0xFF2563EB), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Enable Developer Mode?'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enabling developer mode allows modifying system configurations and diagnostics.'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enter Password / PIN:'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF0F172A)),
                    decoration: InputDecoration(
                      hintText: 'Enter 6-digit PIN'.tr,
                      hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      filled: true,
                      fillColor: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      errorText: errorMessage,
                    ),
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel'.tr,
                    style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (passwordController.text == '723426') {
                      await AuthStore().setDeveloperMode(true);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Developer mode is enabled'.tr),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    } else {
                      setDialogState(() {
                        errorMessage = 'Incorrect password'.tr;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    'Enable'.tr,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
