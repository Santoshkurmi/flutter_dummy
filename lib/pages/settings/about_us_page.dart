import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/translation_service.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  // Safe launcher for websites/external links
  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open page: $urlString'.tr)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred while opening the page'.tr)),
        );
      }
    }
  }

  // Safe launcher for phone calls
  Future<void> _makeCall(BuildContext context, String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+|-'), '');
    final Uri url = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (!await launchUrl(url)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not initiate call to $phoneNumber'.tr)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Phone calling is not supported on this device'.tr)),
        );
      }
    }
  }

  // Safe launcher for emails
  Future<void> _sendEmail(BuildContext context, String emailAddress) async {
    final Uri url = Uri(scheme: 'mailto', path: emailAddress);
    try {
      if (!await launchUrl(url)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open email composer for $emailAddress'.tr)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email composer is not supported on this device'.tr)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Harmonious colors based on mode
    final cardBgColor = isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0);
    final primaryTextColor = isDarkMode ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final hintTextColor = isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8);

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
          'About Developer'.tr,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: primaryTextColor,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          children: [
            const SizedBox(height: 10),
            // Logo Container
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: borderColor,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/bright_logo.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.business_rounded,
                        size: 48,
                        color: Color(0xFF2563EB),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bright Software Pvt. Ltd.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: primaryTextColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pioneering Cooperative Smart Banking Systems'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Description Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: borderColor,
                ),
              ),
              child: Text(
                'Bright Office System is a software company founded in 2012 with a view of taking businesses online, dedicated in the development and implementations of management and information technology. Specializing in financial cooperative software, educational ERP platforms, and secure transaction systems, we deliver digital sovereignty to Nepalese organizations.'.tr,
                style: TextStyle(
                  fontSize: 13,
                  color: secondaryTextColor,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Core Products section
            _buildSectionTitle('Our Core Software Solutions'.tr, hintTextColor),
            const SizedBox(height: 12),

            _buildProductTile(
              title: 'Cooperative Banking System (CBS)'.tr,
              desc: 'High-security cloud core banking platform featuring real-time multi-branch ledger sync, share/savings/loan management, and COPOMIS reporting.'.tr,
              icon: Icons.account_balance_rounded,
              isDarkMode: isDarkMode,
              cardBgColor: cardBgColor,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
            ),
            _buildProductTile(
              title: 'Educational ERP Systems'.tr,
              desc: 'Comprehensive management software for schools and colleges, integrating academic plans, fee billing, payroll, inventory, and online exam modules.'.tr,
              icon: Icons.school_rounded,
              isDarkMode: isDarkMode,
              cardBgColor: cardBgColor,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
            ),
            _buildProductTile(
              title: 'Smart Payments & Utilities'.tr,
              desc: 'Secure digital banking utilities for real-time mobile top-ups, electricity, water, internet payments, remittance, and cooperative QR systems.'.tr,
              icon: Icons.qr_code_scanner_rounded,
              isDarkMode: isDarkMode,
              cardBgColor: cardBgColor,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
            ),
            const SizedBox(height: 28),

            // Branches section
            _buildSectionTitle('Our Offices'.tr, hintTextColor),
            const SizedBox(height: 12),

            _buildBranchCard(
              context: context,
              branchName: 'Head Office'.tr,
              address: 'Bright Building, Tilottama-4, Rupandehi'.tr,
              mapUrl: 'https://www.google.com/maps/place/Bright+Office+System/@27.6907743,83.462084,17z/data=!3m1!4b1!4m6!3m5!1s0x3996868826a8a0ad:0xb0e66979626db605!8m2!3d27.6907743!4d83.4646589!16s%2Fg%2F11c57w2z0x?entry=ttu',
              cardBgColor: cardBgColor,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            _buildBranchCard(
              context: context,
              branchName: 'Corporate Office'.tr,
              address: 'New Baneshwor, Kathmandu'.tr,
              mapUrl: 'https://www.google.com/maps/place/27%C2%B041\'30.0%22N+85%C2%B020\'30.0%22E/@27.6916667,85.3416667,17z/',
              cardBgColor: cardBgColor,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            _buildBranchCard(
              context: context,
              branchName: 'Narayangarh Office'.tr,
              address: 'Sahid Chowk, Bharatpur'.tr,
              mapUrl: 'https://www.google.com/maps/place/27%C2%B034\'12.0%22N+84%C2%B025\'48.0%22E/@27.57,84.43,17z/',
              cardBgColor: cardBgColor,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 28),

            // Contact Channels section
            _buildSectionTitle('Developer Support Channels'.tr, hintTextColor),
            const SizedBox(height: 12),

            _buildContactSection(
              context: context,
              cardBgColor: cardBgColor,
              borderColor: borderColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
            const SizedBox(height: 28),

            // Social Media row
            _buildSectionTitle('Follow Us'.tr, hintTextColor),
            const SizedBox(height: 16),
            _buildSocialRow(context, primaryTextColor),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.5,
        color: color,
      ),
    );
  }

  Widget _buildProductTile({
    required String title,
    required String desc,
    required IconData icon,
    required bool isDarkMode,
    required Color cardBgColor,
    required Color borderColor,
    required Color primaryTextColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchCard({
    required BuildContext context,
    required String branchName,
    required String address,
    required String mapUrl,
    required Color cardBgColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: InkWell(
        onTap: () => _launchUrl(context, mapUrl),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      branchName,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.directions_rounded,
                color: Colors.blue.shade600,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactSection({
    required BuildContext context,
    required Color cardBgColor,
    required Color borderColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Website
          _buildContactRow(
            context: context,
            label: 'Website'.tr,
            value: 'https://brightit.com.np',
            icon: Icons.language_rounded,
            color: const Color(0xFF3B82F6),
            onTap: () => _launchUrl(context, 'https://brightit.com.np'),
            primaryTextColor: primaryTextColor,
          ),
          const Divider(height: 24, thickness: 0.5),

          // Support Phone Numbers
          _buildContactRow(
            context: context,
            label: 'Support Line 1'.tr,
            value: '9857083401',
            icon: Icons.call_rounded,
            color: const Color(0xFF10B981),
            onTap: () => _makeCall(context, '9857083401'),
            primaryTextColor: primaryTextColor,
          ),
          const SizedBox(height: 12),
          _buildContactRow(
            context: context,
            label: 'Support Line 2'.tr,
            value: '9765311214',
            icon: Icons.call_rounded,
            color: const Color(0xFF10B981),
            onTap: () => _makeCall(context, '9765311214'),
            primaryTextColor: primaryTextColor,
          ),
          const Divider(height: 24, thickness: 0.5),

          // Sales Phone Numbers
          _buildContactRow(
            context: context,
            label: 'Sales Inquiries 1'.tr,
            value: '01-5971434',
            icon: Icons.business_center_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () => _makeCall(context, '01-5971434'),
            primaryTextColor: primaryTextColor,
          ),
          const SizedBox(height: 12),
          _buildContactRow(
            context: context,
            label: 'Sales Inquiries 2'.tr,
            value: '9851360070',
            icon: Icons.phone_android_rounded,
            color: const Color(0xFFF59E0B),
            onTap: () => _makeCall(context, '9851360070'),
            primaryTextColor: primaryTextColor,
          ),
          const Divider(height: 24, thickness: 0.5),

          // Emails
          _buildContactRow(
            context: context,
            label: 'Support Email'.tr,
            value: 'support@brightit.com.np',
            icon: Icons.email_rounded,
            color: const Color(0xFFEC4899),
            onTap: () => _sendEmail(context, 'support@brightit.com.np'),
            primaryTextColor: primaryTextColor,
          ),
          const SizedBox(height: 12),
          _buildContactRow(
            context: context,
            label: 'General Inquiries'.tr,
            value: 'info@brightit.com.np',
            icon: Icons.mark_as_unread_rounded,
            color: const Color(0xFF8B5CF6),
            onTap: () => _sendEmail(context, 'info@brightit.com.np'),
            primaryTextColor: primaryTextColor,
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required Color primaryTextColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: primaryTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialRow(BuildContext context, Color primaryTextColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildSocialButton(
          context: context,
          icon: Icons.facebook,
          color: const Color(0xFF1877F2),
          url: 'https://www.facebook.com/brightschoolsoftware/',
          label: 'Facebook',
        ),
        _buildSocialButton(
          context: context,
          icon: Icons.camera_alt_rounded, // Instagram
          color: const Color(0xFFE1306C),
          url: 'https://www.instagram.com/bright_software/',
          label: 'Instagram',
        ),
        _buildSocialButton(
          context: context,
          icon: Icons.play_circle_fill_rounded, // YouTube
          color: const Color(0xFFFF0000),
          url: 'https://www.youtube.com/@brightschool5432',
          label: 'YouTube',
        ),
        _buildSocialButton(
          context: context,
          icon: Icons.work_rounded, // LinkedIn
          color: const Color(0xFF0A66C2),
          url: 'https://np.linkedin.com/company/bright-office-systems',
          label: 'LinkedIn',
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String url,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: () => _launchUrl(context, url),
            tooltip: label,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.tr,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
