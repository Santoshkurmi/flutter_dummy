import 'package:flutter/material.dart';
import '../../store/auth_store.dart';
import '../../services/translation_service.dart';
import 'select_cooperative_page.dart';
import 'status_check_page.dart';


class AppPreferencesSetupPage extends StatelessWidget {
  const AppPreferencesSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthStore(),
      builder: (context, _) {
        final store = AuthStore();
        final isDark = store.isDarkMode;
        final currentLang = store.language;

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Navigator.canPop(context) ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              onPressed: () => Navigator.pop(context),
            ) : null,
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              children: [
                // Icon Header
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_suggest_rounded,
                      color: Color(0xFF2563EB),
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Screen Title & Subtitle
                Center(
                  child: Text(
                    'Customize Experience'.tr,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Set your preferred language and layout theme style'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // SECTION 1: Language Config Cards
                Text(
                  'Choose Language'.tr.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // English Selector
                    Expanded(
                      child: _buildSelectionCard(
                        context: context,
                        title: 'English',
                        subtitle: 'Default language',
                        isSelected: currentLang == 'en',
                        icon: Icons.language_rounded,
                        isDark: isDark,
                        onTap: () => store.setLanguage('en'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Nepali Selector
                    Expanded(
                      child: _buildSelectionCard(
                        context: context,
                        title: 'नेपाली',
                        subtitle: 'स्थानीय भाषा',
                        isSelected: currentLang == 'ne',
                        icon: Icons.translate_rounded,
                        isDark: isDark,
                        onTap: () => store.setLanguage('ne'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // SECTION 2: Theme Config Cards
                Text(
                  'Choose Theme'.tr.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF475569),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // System Mode
                    Expanded(
                      child: _buildSelectionCard(
                        context: context,
                        title: 'System',
                        subtitle: 'Auto detect',
                        isSelected: store.themeMode == 'system',
                        icon: Icons.brightness_auto_rounded,
                        isDark: isDark,
                        onTap: () => store.setThemeMode('system'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Light Mode
                    Expanded(
                      child: _buildSelectionCard(
                        context: context,
                        title: 'Light'.tr,
                        subtitle: 'Bright',
                        isSelected: store.themeMode == 'light',
                        icon: Icons.light_mode_rounded,
                        isDark: isDark,
                        onTap: () => store.setThemeMode('light'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Dark Mode
                    Expanded(
                      child: _buildSelectionCard(
                        context: context,
                        title: 'Dark'.tr,
                        subtitle: 'Sleek',
                        isSelected: store.themeMode == 'dark',
                        icon: Icons.dark_mode_rounded,
                        isDark: isDark,
                        onTap: () => store.setThemeMode('dark'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),

                // Proceed Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.1 : 0.15),
                        blurRadius: 15,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (store.isCustomApp) {
                        await store.setPreferencesSetupCompleted(true);
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const StatusCheckPage(),
                            ),
                            (route) => false,
                          );
                        }
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SelectCooperativePage(),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          store.isCustomApp
                              ? 'Proceed to Mobile Banking'.tr
                              : 'Proceed to Select Cooperative'.tr,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isSelected,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB).withValues(alpha: isDark ? 0.15 : 0.08)
              : (isDark ? const Color(0xFF0F172A) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04)),
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF2563EB)
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                size: 20,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
