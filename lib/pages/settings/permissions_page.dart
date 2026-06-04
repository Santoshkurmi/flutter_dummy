import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../services/translation_service.dart';
import '../../store/auth_store.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> with WidgetsBindingObserver {
  Map<Permission, PermissionStatus> _statuses = {};
  bool _isLoading = true;
  List<Map<String, dynamic>> _permissionItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAndCheck();
  }

  Future<void> _initAndCheck() async {
    await _initializePermissionItems();
    await _checkAllPermissions();
  }

  Future<void> _initializePermissionItems() async {
    bool isAndroidUnder29 = false;
    if (Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        isAndroidUnder29 = androidInfo.version.sdkInt < 29;
      } catch (_) {
        isAndroidUnder29 = true;
      }
    }

    final List<Map<String, dynamic>> items = [
      {
        'permission': Permission.location,
        'title': 'Location',
        'icon': Icons.location_on_rounded,
        'color': const Color(0xFF3B82F6),
        'description': 'Used to determine device location during member registration, device synchronization, and branch search.',
      },
      {
        'permission': Permission.camera,
        'title': 'Camera',
        'icon': Icons.camera_alt_rounded,
        'color': const Color(0xFF10B981),
        'description': 'Required for merchant QR payments, scanned receipts, and profile picture verification.',
      },
    ];

    if (Platform.isIOS) {
      items.add({
        'permission': Permission.photos,
        'title': 'Photos',
        'icon': Icons.image_rounded,
        'color': const Color(0xFFF59E0B),
        'description': 'Allows saving custom QR codes directly to your Photo gallery and choosing existing QR images to scan.',
      });
    } else {
      if (isAndroidUnder29) {
        items.add({
          'permission': Permission.storage,
          'title': 'Storage',
          'icon': Icons.folder_rounded,
          'color': const Color(0xFFF59E0B),
          'description': 'Allows saving transaction receipts, statements, and other PDF documents directly to your downloads folder.',
        });
      } else {
        items.add({
          'permission': Permission.storage,
          'title': 'Storage',
          'icon': Icons.folder_rounded,
          'color': const Color(0xFFF59E0B),
          'description': 'Allows saving transaction receipts, statements, and other PDF documents. Managed automatically by the system.',
          'isNotRequired': true,
        });
      }
    }

    items.add({
      'permission': Permission.notification,
      'title': 'Notification',
      'icon': Icons.notifications_rounded,
      'color': const Color(0xFF8B5CF6),
      'description': 'Enables receipt of transaction alerts, statement alerts, security notifications, and critical announcements.',
    });

    if (mounted) {
      setState(() {
        _permissionItems = items;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    final Map<Permission, PermissionStatus> newStatuses = {};
    for (var item in _permissionItems) {
      final perm = item['permission'] as Permission;
      final isNotRequired = item['isNotRequired'] as bool? ?? false;
      if (isNotRequired) {
        newStatuses[perm] = PermissionStatus.granted;
      } else {
        newStatuses[perm] = await perm.status;
      }
    }

    if (mounted) {
      setState(() {
        _statuses = newStatuses;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    if (mounted) {
      setState(() {
        _statuses[permission] = status;
      });
    }
    _checkAllPermissions();
  }

  void _showSettingsDialog(String title, String message) {
    final isDarkMode = AuthStore().isDarkMode;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title.tr, style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : const Color(0xFF0F172A))),
          content: Text(message.tr, style: TextStyle(color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'.tr, style: const TextStyle(color: Color(0xFF64748B))),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: Text('Open Settings'.tr, style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBadge(PermissionStatus status, {bool isNotRequired = false}) {
    if (isNotRequired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Not Required'.tr,
          style: const TextStyle(
            color: Color(0xFF10B981),
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    }

    String label = 'Denied';
    Color color = const Color(0xFFEF4444);
    Color bgColor = const Color(0xFFEF4444).withValues(alpha: 0.1);

    if (status.isGranted) {
      label = 'Granted';
      color = const Color(0xFF10B981);
      bgColor = const Color(0xFF10B981).withValues(alpha: 0.1);
    } else if (status.isPermanentlyDenied) {
      label = 'Permanently Denied';
      color = const Color(0xFFEF4444);
      bgColor = const Color(0xFFEF4444).withValues(alpha: 0.1);
    } else if (status.isRestricted) {
      label = 'Restricted';
      color = const Color(0xFF64748B);
      bgColor = const Color(0xFF64748B).withValues(alpha: 0.1);
    } else if (status.isLimited) {
      label = 'Limited';
      color = const Color(0xFF3B82F6);
      bgColor = const Color(0xFF3B82F6).withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.tr,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AuthStore().isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF020617) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context) ? IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ) : null,
        title: Text(
          'App Permissions'.tr,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF2563EB))))
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                children: [
                  Text(
                    'Permissions'.tr.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage device permissions for location, camera, storage, and notifications.'.tr,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._permissionItems.map((item) {
                    final perm = item['permission'] as Permission;
                    final isNotRequired = item['isNotRequired'] as bool? ?? false;
                    final status = _statuses[perm] ?? PermissionStatus.denied;
                    final title = item['title'] as String;
                    final description = item['description'] as String;
                    final icon = item['icon'] as IconData;
                    final color = item['color'] as Color;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(icon, color: color, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title.tr,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    _buildStatusBadge(status, isNotRequired: isNotRequired),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (isNotRequired)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF10B981),
                                    size: 28,
                                  ),
                                )
                              else
                                Switch.adaptive(
                                  value: status.isGranted,
                                  activeTrackColor: const Color(0xFF10B981),
                                  thumbColor: WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) return Colors.white;
                                    return null;
                                  }),
                                  onChanged: (val) {
                                    if (val) {
                                      if (status.isPermanentlyDenied) {
                                        _showSettingsDialog(
                                          'Permission Required',
                                          'Please enable $title permission in App Settings to proceed.',
                                        );
                                      } else {
                                        _requestPermission(perm);
                                      }
                                    } else {
                                      _showSettingsDialog(
                                        'Disable Permission',
                                        'To disable $title permission, please open App Settings.',
                                      );
                                    }
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFEFF6FF),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            description.tr,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
      ),
    );
  }
}
