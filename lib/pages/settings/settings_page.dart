import 'package:flutter/material.dart';
import 'dart:io';
import '../../store/auth_store.dart';
import '../../store/notification_store.dart';
import '../../services/translation_service.dart';
import '../../services/theme_color_service.dart';
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
    final colors = context.colors;
    final isDarkMode = AuthStore().isDarkMode;
    final authStore = AuthStore();

    return Scaffold(
      backgroundColor: colors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context) ? IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colors.primaryText,
          ),
          onPressed: () => Navigator.pop(context),
        ) : null,
        title: Text(
          'Settings'.tr,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: colors.primaryText,
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
                    MaterialPageRoute(settings: const RouteSettings(name: 'BiometricSetupPage'), builder: (_) => const BiometricSetupPage()),
                  ).then((_) => setState(() {}));
                } else {
                  await authStore.setBiometricEnabled(false);
                  setState(() {});
                }
              },
              icon: Icons.fingerprint_rounded,
              isDarkMode: isDarkMode,
            ),

            if (authStore.isBiometricEnabled) ...[
              const SizedBox(height: 16),
              _buildSectionHeader('Auto Biometric Popup'.tr, isDarkMode),
              const SizedBox(height: 8),
              _buildAutoBiometricSelector(isDarkMode, authStore),
            ],

            const SizedBox(height: 24),

            // Section 4: Theme
            _buildSectionHeader('THEME'.tr, isDarkMode),
            const SizedBox(height: 12),
            _buildThemeSelector(isDarkMode, authStore),
            const SizedBox(height: 16),
            _buildAccentColorSelector(isDarkMode, authStore),
            const SizedBox(height: 16),
            _buildSectionHeader('Transition'.tr, isDarkMode),
            // const SizedBox(height: 16),

            _buildToggleItem(
              title: Platform.isIOS
                  ? 'Android Transition Style'.tr
                  : 'Iphone Transition Style'.tr,
              subtitle: Platform.isIOS
                  ? 'Use Android\'s slide-fade page navigation instead of iOS Cupertino transition'.tr
                  : 'Use iOS-style predictive back gesture and horizontal slide navigation'.tr,
              value: authStore.customPageTransitionEnabled,
              onChanged: (val) async {
                await authStore.setCustomPageTransitionEnabled(val);
                setState(() {});
              },
              icon: Icons.animation_rounded,
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 24),

            // Section 5: Language
            _buildSectionHeader('LANGUAGE'.tr, isDarkMode),
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
    final colors = context.colors;
    final currentMode = authStore.themeMode;
    final modes = [
      {'key': 'system', 'label': 'System'.tr, 'icon': Icons.brightness_auto_rounded},
      {'key': 'light', 'label': 'Light'.tr, 'icon': Icons.light_mode_rounded},
      {'key': 'dark', 'label': 'Dark'.tr, 'icon': Icons.dark_mode_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.chipBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border,
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
                      ? (isDarkMode ? colors.inputFill : colors.containerBackground)
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
                          ? colors.accent
                          : colors.secondaryText,
                      size: 18,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? colors.primaryText
                            : colors.secondaryText,
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

  Widget _buildAccentColorSelector(bool isDarkMode, AuthStore authStore) {
    final colors = context.colors;
    final currentTheme = authStore.colorTheme;
    final themes = [
      {'key': 'default', 'label': 'Blue'.tr, 'color': const Color(0xFF2563EB)},
      {'key': 'emerald', 'label': 'Green'.tr, 'color': const Color(0xFF059669)},
      {'key': 'orange', 'label': 'Orange'.tr, 'color': const Color(0xFFEA580C)},
      {'key': 'purple', 'label': 'Purple'.tr, 'color': const Color(0xFF7C3AED)},
      {'key': 'rose', 'label': 'Rose'.tr, 'color': const Color(0xFFE11D48)},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: colors.chipBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accent Color'.tr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colors.secondaryText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: themes.map((theme) {
              final isSelected = currentTheme == theme['key'];
              final themeColor = theme['color'] as Color;
              return GestureDetector(
                onTap: () => authStore.setColorTheme(theme['key'] as String),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: themeColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? (isDarkMode ? Colors.white : const Color(0xFF0F172A))
                              : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: themeColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      theme['label'] as String,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? colors.primaryText : colors.secondaryText,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(bool isDarkMode, AuthStore authStore) {
    final colors = context.colors;
    final currentLang = authStore.language;
    final langs = [
      {'key': 'en', 'label': 'English', 'icon': Icons.language_rounded},
      {'key': 'ne', 'label': 'नेपाली', 'icon': Icons.translate_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.chipBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border,
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
                      ? (isDarkMode ? colors.inputFill : colors.containerBackground)
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
                          ? colors.accent
                          : colors.secondaryText,
                      size: 18,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? colors.primaryText
                            : colors.secondaryText,
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

  Widget _buildAutoBiometricSelector(bool isDarkMode, AuthStore authStore) {
    final colors = context.colors;
    final currentBehavior = authStore.autoBiometricBehavior;
    final options = [
      {'key': 'sometime', 'label': 'Sometime'.tr, 'icon': Icons.timer_outlined},
      {'key': 'never', 'label': 'Never'.tr, 'icon': Icons.block_rounded},
      {'key': 'always', 'label': 'Always'.tr, 'icon': Icons.loop_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.chipBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Row(
        children: options.map((opt) {
          final isSelected = currentBehavior == opt['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () async {
                await authStore.setAutoBiometricBehavior(opt['key'] as String);
                setState(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDarkMode ? colors.inputFill : colors.containerBackground)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected && !isDarkMode
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]
                      : [],
                ),
                child: Column(
                  children: [
                    Icon(
                      opt['icon'] as IconData,
                      color: isSelected
                          ? colors.accent
                          : colors.secondaryText,
                      size: 18,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opt['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? colors.primaryText
                            : colors.secondaryText,
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
    final colors = context.colors;
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: colors.secondaryText,
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
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors.accent, size: 20),
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
                    color: colors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: colors.secondaryText,
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
            activeTrackColor: colors.accent,
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
    final colors = context.colors;
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
                ? colors.accent 
                : colors.chipBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? colors.accent 
                  : colors.chipBorder,
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
                  : colors.primaryText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationLanguageSelector(bool isDarkMode, AuthStore authStore) {
    final colors = context.colors;
    final currentLang = authStore.notificationLanguage;
    final langs = [
      {'key': 'en', 'label': 'English'.tr, 'icon': Icons.language_rounded},
      {'key': 'ne', 'label': 'नेपाली'.tr, 'icon': Icons.translate_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.chipBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border,
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
                      ? (isDarkMode ? colors.inputFill : colors.containerBackground)
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
                          ? colors.accent
                          : colors.secondaryText,
                      size: 18,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lang['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? colors.primaryText
                            : colors.secondaryText,
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

  void _confirmReset(BuildContext context, AuthStore authStore, bool isDarkMode) {
    final colors = context.colors;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: colors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Reset Settings?'.tr, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            'This will revert all customization preferences, switches, limits, and authentication profiles to default state.'.tr,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'.tr, style: TextStyle(color: colors.secondaryText)),
            ),
            TextButton(
              onPressed: () async {
                await authStore.clearAll();
                if (context.mounted) {
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
