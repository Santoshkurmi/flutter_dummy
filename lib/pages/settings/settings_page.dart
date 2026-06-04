import 'package:flutter/material.dart';
import 'dart:io';
import '../../store/auth_store.dart';
import '../../store/notification_store.dart';
import '../../services/translation_service.dart';
import '../../services/api_service.dart';
import 'biometric_setup_page.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    AuthStore().addListener(_onStoreChange);
  }

  @override
  void dispose() {
    AuthStore().removeListener(_onStoreChange);
    super.dispose();
  }

  void _onStoreChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AuthStore().isDarkMode;
    final authStore = AuthStore();

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
          'Settings'.tr,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          children: [
            if (Platform.isAndroid) ...[
              // Section 1: Notifications
              _buildSectionHeader('NOTIFICATIONS'.tr, isDarkMode),
              
              _buildToggleItem(
                title: 'Show Date Notification'.tr,
                subtitle: 'Show persistent Nepali calendar date and events in status bar'.tr,
                value: authStore.showDateNotification,
                onChanged: (val) async {
                  if (val) {
                    final status = await Permission.notification.status;
                    if (!status.isGranted) {
                      await Permission.notification.request();
                    }
                  }
                  await authStore.setShowDateNotification(val);
                  await NotificationStore().updateDateNotification(val);
                  setState(() {});
                },
                icon: Icons.calendar_month_rounded,
                isDarkMode: isDarkMode,
              ),

              if (authStore.showDateNotification) ...[
                const SizedBox(height: 16),
                _buildSectionHeader('Notification Language'.tr, isDarkMode),
                const SizedBox(height: 8),
                _buildNotificationLanguageSelector(isDarkMode, authStore),
              ],

              const SizedBox(height: 24),
            ],

            // Section 2: Security
            _buildSectionHeader('SECURITY'.tr, isDarkMode),
            
            // Biometric Switch
            _buildToggleItem(
              title: 'Biometric Login'.tr,
              subtitle: 'Unlock account and authorise using hardware fingerprint'.tr,
              value: authStore.isBiometricEnabled,
              onChanged: (val) async {
                if (val) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BiometricSetupPage()),
                  ).then((_) => setState(() {}));
                } else {
                  await authStore.setBiometricEnabled(false);
                  setState(() {});
                }
              },
              icon: Icons.fingerprint_rounded,
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 24),

            // Section 2.5: Cache Settings
            _buildSectionHeader('DATA & CACHE'.tr, isDarkMode),
            
            // Enable Caching Switch
            _buildToggleItem(
              title: 'Enable Caching'.tr,
              subtitle: 'Store responses locally to reduce data usage and load pages faster'.tr,
              value: authStore.enableCaching,
              onChanged: (val) async {
                if (val) {
                  await authStore.setEnableCaching(true);
                  setState(() {});
                } else {
                  _showDisableCacheDialog(context, authStore, isDarkMode);
                }
              },
              icon: Icons.cached_rounded,
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 24),
            // Section 4: Appearance
            _buildSectionHeader('APPEARANCE'.tr, isDarkMode),
            const SizedBox(height: 12),
            _buildThemeSelector(isDarkMode, authStore),

            const SizedBox(height: 12),
            _buildLanguageSelector(isDarkMode, authStore),

            const SizedBox(height: 32),

            // Section 5: Reset
            ElevatedButton.icon(
              onPressed: () => _confirmReset(context, authStore, isDarkMode),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
                foregroundColor: const Color(0xFFEF4444),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                  ),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Reset Application Settings'.tr,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(bool isDarkMode, AuthStore authStore) {
    final currentMode = authStore.themeMode;
    final modes = [
      {'key': 'system', 'label': 'System'.tr, 'icon': Icons.brightness_auto_rounded},
      {'key': 'light', 'label': 'Light'.tr, 'icon': Icons.light_mode_rounded},
      {'key': 'dark', 'label': 'Dark'.tr, 'icon': Icons.dark_mode_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: modes.map((mode) {
          final isSelected = currentMode == mode['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () => authStore.setThemeMode(mode['key'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDarkMode ? const Color(0xFF1E293B) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected && !isDarkMode
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Column(
                  children: [
                    Icon(
                      mode['icon'] as IconData,
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                      size: 18,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? (isDarkMode ? Colors.white : const Color(0xFF0F172A))
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLanguageSelector(bool isDarkMode, AuthStore authStore) {
    final currentLang = authStore.language;
    final langs = [
      {'key': 'en', 'label': 'English', 'icon': Icons.language_rounded},
      {'key': 'ne', 'label': 'नेपाली', 'icon': Icons.translate_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: langs.map((lang) {
          final isSelected = currentLang == lang['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () => authStore.setLanguage(lang['key'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDarkMode ? const Color(0xFF1E293B) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected && !isDarkMode
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Column(
                  children: [
                    Icon(
                      lang['icon'] as IconData,
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                      size: 18,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? (isDarkMode ? Colors.white : const Color(0xFF0F172A))
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDarkMode) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF2563EB),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitPill(String value, String label, AuthStore authStore, bool isDarkMode) {
    final isSelected = authStore.dailyLimit == value;
    return Expanded(
      child: InkWell(
        onTap: () async {
          await authStore.setDailyLimit(value);
          setState(() {});
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF2563EB) 
                : (isDarkMode ? Colors.white.withValues(alpha: 0.03) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFF2563EB) 
                  : (isDarkMode ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFCBD5E1)),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected 
                  ? Colors.white 
                  : (isDarkMode ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationLanguageSelector(bool isDarkMode, AuthStore authStore) {
    final currentLang = authStore.notificationLanguage;
    final langs = [
      {'key': 'en', 'label': 'English'.tr, 'icon': Icons.language_rounded},
      {'key': 'ne', 'label': 'नेपाली'.tr, 'icon': Icons.translate_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: langs.map((lang) {
          final isSelected = currentLang == lang['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () async {
                await authStore.setNotificationLanguage(lang['key'] as String);
                await NotificationStore().updateDateNotification(true);
                setState(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDarkMode ? const Color(0xFF1E293B) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected && !isDarkMode
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Column(
                  children: [
                    Icon(
                      lang['icon'] as IconData,
                      color: isSelected
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF64748B),
                      size: 18,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? (isDarkMode ? Colors.white : const Color(0xFF0F172A))
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showDisableCacheDialog(BuildContext context, AuthStore authStore, bool isDarkMode) {
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
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Disable Caching?'.tr,
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
                    'Disabling cache is not recommended and should only be used for testing purposes.'.tr,
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
                      color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF64748B),
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
                      await authStore.setEnableCaching(false);
                      await ApiService.clearCache();
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                      setState(() {});
                    } else {
                      setDialogState(() {
                        errorMessage = 'Incorrect password'.tr;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    'Disable'.tr,
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

  void _confirmReset(BuildContext context, AuthStore authStore, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Reset Settings?'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            'This will revert all customization preferences, switches, limits, and authentication profiles to default state.'.tr,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'.tr, style: const TextStyle(color: Color(0xFF64748B))),
            ),
            TextButton(
              onPressed: () async {
                await authStore.clearAll();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                }
              },
              child: Text('Reset'.tr, style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
