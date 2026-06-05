import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../services/translation_service.dart';
import '../../store/auth_store.dart';
import 'changelogs_page.dart';

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});

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

    return Scaffold(
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
      ),
      body: SafeArea(
        child: FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                ),
              );
            }

            final packageInfo = snapshot.data;
            final appName = packageInfo?.appName ?? 'Bright Sahakari';
            final packageName = packageInfo?.packageName ?? 'N/A';
            final version = packageInfo?.version ?? 'N/A';
            final buildNumber = packageInfo?.buildNumber ?? 'N/A';

            return ListView(
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
                      _buildSpecRow(
                        label: 'App Version'.tr,
                        value: _formatNepaliNumbers(version),
                        icon: Icons.info_outline_rounded,
                        accentColor: accentColor,
                        isDarkMode: isDarkMode,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
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
            );
          },
        ),
      ),
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
}
