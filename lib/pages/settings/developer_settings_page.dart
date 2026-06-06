import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../store/auth_store.dart';
import '../../services/translation_service.dart';
import '../../services/api_service.dart';
import '../../services/theme_color_service.dart';

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
    final colors = context.colors;
    final isDarkMode = context.isDarkMode;
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
          'Developer Settings'.tr,
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



            const SizedBox(height: 16),

            _buildToggleItem(
              title: 'Show FPS'.tr,
              subtitle: 'Show real-time FPS counter overlay'.tr,
              value: authStore.showFps,
              onChanged: (val) async {
                await authStore.setShowFps(val);
                setState(() {});
              },
              icon: Icons.av_timer_rounded,
              isDarkMode: isDarkMode,
            ),

            if (!kReleaseMode) ...[
              const SizedBox(height: 16),
              _buildToggleItem(
                title: 'Performance Monitor'.tr,
                subtitle: 'Show floating performance monitoring widget'.tr,
                value: authStore.showPerformanceMonitor,
                onChanged: (val) async {
                  await authStore.setShowPerformanceMonitor(val);
                  setState(() {});
                },
                icon: Icons.monitor_heart_rounded,
                isDarkMode: isDarkMode,
              ),
            ],
          ],
        ),
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

  void _showDisableCacheDialog(BuildContext context, AuthStore authStore, bool isDarkMode) {
    final colors = context.colors;
    final TextEditingController passwordController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: colors.cardBackground,
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
                        color: colors.primaryText,
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
                      color: colors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enter Password / PIN:'.tr,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colors.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: colors.primaryText),
                    decoration: InputDecoration(
                      hintText: 'Enter 6-digit PIN'.tr,
                      hintStyle: TextStyle(color: colors.secondaryText, fontSize: 14),
                      filled: true,
                      fillColor: colors.inputFill,
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
                    style: TextStyle(color: colors.secondaryText, fontWeight: FontWeight.w600),
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
