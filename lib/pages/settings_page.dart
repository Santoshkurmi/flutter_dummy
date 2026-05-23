import 'package:flutter/material.dart';
import '../store/auth_store.dart';
import 'biometric_setup_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authStore = AuthStore();

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF020617) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
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
            // Section 1: Security & Preferences
            _buildSectionHeader('Preference Settings', isDarkMode),
            
            // Push Notifications Switch
            _buildToggleItem(
              title: 'Push Notifications',
              subtitle: 'Receive real-time transaction updates and alerts',
              value: authStore.pushEnabled,
              onChanged: (val) async {
                await authStore.setPushEnabled(val);
                setState(() {});
              },
              icon: Icons.notifications_active_rounded,
              isDarkMode: isDarkMode,
            ),
            
            // Biometric Switch
            _buildToggleItem(
              title: 'Biometric Access Bypass',
              subtitle: 'Unlock account and authorise using hardware fingerprint',
              value: authStore.isBiometricEnabled,
              onChanged: (val) async {
                if (val) {
                  // Launch Biometric setup to authenticate and enroll keys properly
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
            
            // SMS Alerts Switch
            _buildToggleItem(
              title: 'SMS Alerts Gateway',
              subtitle: 'Backup copy of standard messages over cellular connection',
              value: authStore.smsAlertsEnabled,
              onChanged: (val) async {
                await authStore.setSmsAlertsEnabled(val);
                setState(() {});
              },
              icon: Icons.sms_rounded,
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 24),
            
            // Section 2: Transaction Limit Rules
            _buildSectionHeader('Transaction Thresholds', isDarkMode),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Transfer limit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Configure absolute limits allowed for mobile banking services',
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

            const SizedBox(height: 32),

            // Section 3: Reset / System options
            ElevatedButton.icon(
              onPressed: () => _confirmReset(context, authStore, isDarkMode),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444).withOpacity(0.08),
                foregroundColor: const Color(0xFFEF4444),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: const Color(0xFFEF4444).withOpacity(0.2),
                  ),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text(
                'Reset Application Settings',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
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
          color: isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.08),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2563EB),
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
                : (isDarkMode ? Colors.white.withOpacity(0.03) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? const Color(0xFF2563EB) 
                  : (isDarkMode ? Colors.white.withOpacity(0.06) : const Color(0xFFCBD5E1)),
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
          title: const Text('Reset Settings?', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'This will revert all customization preferences, switches, limits, and authentication profiles to default state.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            TextButton(
              onPressed: () async {
                await authStore.clearAll();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                }
              },
              child: const Text('Reset', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
