import 'package:flutter/material.dart';
import '../../store/auth_store.dart';
import '../../services/translation_service.dart';
import '../../services/theme_color_service.dart';
import '../../widgets/cached_image.dart';
import '../settings/settings_page.dart';
import '../settings/permissions_page.dart';
import '../auth/register_member_page.dart';
import '../services/nepali_calendar_page.dart';
import '../services/date_conversion_page.dart';
import '../settings/about_us_page.dart';
import '../settings/about_app_page.dart';
import '../settings/developer_settings_page.dart';
import '../services/qr_generator_page.dart';
import '../settings/member_details_page.dart';
import '../settings/cooperative_details_page.dart';

class ProfileTab extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onLogout;

  const ProfileTab({
    super.key,
    required this.isDarkMode,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = context.isDarkMode;

    return AnimatedBuilder(
      animation: AuthStore(),
      builder: (context, _) {
        final authStore = AuthStore();
        final profile = authStore.profile;
        final coop = authStore.selectedCooperative;
        final String currentLang = authStore.language;

        final String name = currentLang == 'ne'
            ? (profile?['member_name_nepali'] ?? profile?['member_name'] ?? 'Sahakari User')
            : (profile?['member_name'] ?? 'Sahakari User');

        final mobile = profile?['mobile'] ?? authStore.mobile ?? '98XXXXXXXX';
        
        final coopName = currentLang == 'ne'
            ? (coop?['name_nepali'] ?? coop?['name'] ?? 'Bright Saving & Credit Co-operative')
            : (coop?['name'] ?? 'Bright Saving & Credit Co-operative');

        final profileImagePath = profile?['profile_image_path'];
        final bool hasValidImage = profileImagePath != null && profileImagePath.toString().isNotEmpty;

        final Widget initialsPlaceholder = Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [colors.accent.withValues(alpha: 0.8), colors.accent]),
          ),
          child: Center(
            child: Text(
              name.isEmpty ? 'S' : name.substring(0, 1),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        );

        final String memberDetailsLabel = 'Member Details'.tr;
        final String memberDetailsSubtitle = 'View personal specifications, address and nominee details'.tr;

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            const SizedBox(height: 35),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colors.cardBackground,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colors.border,
                ),
                boxShadow: isDarkMode
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
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: hasValidImage
                        ? CachedImage(
                            imageUrl: profileImagePath,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => initialsPlaceholder,
                            placeholder: initialsPlaceholder,
                          )
                        : initialsPlaceholder,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(mobile, style: TextStyle(color: colors.secondaryText, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'MEMBER & COOPERATIVE IDENTITY'.tr,
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            _profileActionOption(context, Icons.person_outline_rounded, memberDetailsLabel, memberDetailsSubtitle, const MemberDetailsPage()),
            _profileActionOption(context, Icons.account_balance_rounded, 'Cooperative Bank'.tr, coopName, const CooperativeDetailsPage()),
            const SizedBox(height: 24),
            Text(
              'UTILITY SERVICES & PREFERENCES'.tr,
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            _profileActionOption(context, Icons.settings_rounded, 'App Preferences'.tr, 'Configure alerts, daily limits and fingerprint setup'.tr, const SettingsPage()),
            _profileActionOption(context, Icons.security_rounded, 'Permissions'.tr, 'Manage device permissions for location, camera, storage, and notifications.'.tr, const PermissionsPage()),
            _profileActionOption(context, Icons.app_registration_rounded, 'Member Registration'.tr, 'Become a member by filling member-registration wizard'.tr, const RegisterMemberPage()),
            _profileActionOption(context, Icons.qr_code_2_rounded, 'QR Generator'.tr, 'Generate and download custom cooperative QR codes'.tr, QRGeneratorPage(isDarkMode: isDarkMode)),
            _profileActionOption(context, Icons.calendar_month_rounded, 'Nepali Calendar'.tr, 'View Bikram Sambat dates, Nepalese holidays and board runs'.tr, const NepaliCalendarPage()),
            _profileActionOption(context, Icons.swap_horizontal_circle_outlined, 'Date Utility'.tr, 'Convert between BS and AD, calculate date difference'.tr, const DateConversionPage()),
            if (authStore.isDeveloperMode) ...[
              _profileActionOption(
                context,
                Icons.developer_mode_rounded,
                'Developer Settings'.tr,
                'Configure caching, network overrides and diagnostic options.'.tr,
                const DeveloperSettingsPage(),
              ),
            ],
            _profileActionOption(context, Icons.info_outline_rounded, 'About Developer'.tr, 'Technical details, architecture and specs by Bright Software'.tr, const AboutUsPage()),
            _profileActionOption(context, Icons.smartphone_rounded, 'About App'.tr, 'View app specs, version code and development history changelogs'.tr, const AboutAppPage()),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.power_settings_new_rounded),
                  const SizedBox(width: 10),
                  Text('Logout Account'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }

  Widget _profileActionOption(BuildContext context, IconData icon, String title, String subtitle, Widget targetPage) {
    final colors = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.border,
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(settings: RouteSettings(name: targetPage.runtimeType.toString()), builder: (_) => targetPage)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: colors.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: colors.primaryText,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: colors.secondaryText, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: colors.secondaryText, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
