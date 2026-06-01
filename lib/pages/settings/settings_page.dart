import 'package:flutter/material.dart';
import '../../store/auth_store.dart';
import '../../services/translation_service.dart';
import '../../services/api_service.dart';
import 'biometric_setup_page.dart';

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
            // Section 1: Notifications
            _buildSectionHeader('NOTIFICATIONS'.tr, isDarkMode),
            
            // Push Notifications Switch
            _buildToggleItem(
              title: 'Push Notifications'.tr,
              subtitle: 'Receive real-time transaction updates and alerts'.tr,
              value: authStore.pushEnabled,
              onChanged: (val) async {
                await authStore.setPushEnabled(val);
                setState(() {});
              },
              icon: Icons.notifications_active_rounded,
              isDarkMode: isDarkMode,
            ),
            
            // SMS Alerts Switch
            _buildToggleItem(
              title: 'SMS Alerts'.tr,
              subtitle: 'Backup copy of standard messages over cellular connection'.tr,
              value: authStore.smsAlertsEnabled,
              onChanged: (val) async {
                await authStore.setSmsAlertsEnabled(val);
                setState(() {});
              },
              icon: Icons.sms_rounded,
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 24),

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
                await authStore.setEnableCaching(val);
                if (!val) {
                  await ApiService.clearCache();
                }
                setState(() {});
              },
              icon: Icons.cached_rounded,
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 24),
            
            // Section 3: Transaction Limits
            _buildSectionHeader('TRANSACTION LIMITS'.tr, isDarkMode),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Transfer Limit'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Configure absolute limits allowed for mobile banking services'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildLimitPill('10000', 'Rs. 10K', authStore, isDarkMode),
                      const SizedBox(width: 8),
                      _buildLimitPill('50000', 'Rs. 50K', authStore, isDarkMode),
                      const SizedBox(width: 8),
                      _buildLimitPill('100000', 'Rs. 100K', authStore, isDarkMode),
                    ],
                  ),
                ],
              ),
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
