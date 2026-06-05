import 'package:flutter/material.dart';
import '../../store/auth_store.dart';
import '../../services/translation_service.dart';
import '../../services/api_service.dart';

class DeveloperSettingsPage extends StatefulWidget {
  const DeveloperSettingsPage({super.key});

  @override
  State<DeveloperSettingsPage> createState() => _DeveloperSettingsPageState();
}

class _DeveloperSettingsPageState extends State<DeveloperSettingsPage> {
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
    final authStore = AuthStore();
    final isDarkMode = authStore.isDarkMode;

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
          'Developer Settings'.tr,
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
            // Section 1: Developer Mode
            _buildSectionHeader('DEVELOPER PREFERENCES'.tr, isDarkMode),
            
            _buildToggleItem(
              title: 'Developer Mode'.tr,
              subtitle: 'Enable or disable developer settings and diagnostic panels'.tr,
              value: authStore.isDeveloperMode,
              onChanged: (val) async {
                if (!val) {
                  // Disable developer mode, reset settings, and navigate back
                  await authStore.disableDeveloperMode();
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
              icon: Icons.developer_mode_rounded,
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 24),

            // Section 2: Diagnostics & Caching
            _buildSectionHeader('DIAGNOSTICS & CACHE'.tr, isDarkMode),

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
                    color: const Color(0xFF64748B),
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
}
