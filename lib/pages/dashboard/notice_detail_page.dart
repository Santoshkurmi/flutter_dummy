import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/translation_service.dart';

class NoticeDetailPage extends StatelessWidget {
  final Map<String, dynamic> notice;
  final bool isDarkMode;

  const NoticeDetailPage({
    super.key,
    required this.notice,
    required this.isDarkMode,
  });

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

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final cardBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0);

    final String title = notice['title'] ?? '';
    final String description = notice['description'] ?? '';
    final String content = notice['content'] ?? '';
    final imagePath = notice['image_path'];
    final int priority = notice['priority'] ?? 0;
    final String dateBs = notice['start_date_bs'] ?? '';
    final String endDateBs = notice['end_date_bs'] ?? '';
    final hasImage = imagePath != null && imagePath.toString().isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: primaryTextColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notice Details'.tr,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: primaryTextColor,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice Primary Image (if available)
              if (hasImage) ...[
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.network(
                      imagePath,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Notice Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: primaryTextColor,
                  letterSpacing: -0.5,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),

              // Badges Wrap
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Priority Badge
                  if (priority >= 2)
                    _buildBadge('High Priority'.tr, const Color(0xFFFEE2E2), const Color(0xFFEF4444))
                  else if (priority == 1)
                    _buildBadge('Medium Priority'.tr, const Color(0xFFFEF3C7), const Color(0xFFD97706)),

                  // Start Date Badge
                  if (dateBs.isNotEmpty)
                    _buildBadge(
                      'Published: ${dateBs.trd}'.tr,
                      isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                      isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                    ),

                  // End Date Badge
                  if (endDateBs.isNotEmpty)
                    _buildBadge(
                      'Expires: ${endDateBs.trd}'.tr,
                      isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7),
                      isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Teaser summary box
              if (description.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontStyle: FontStyle.italic,
                      color: secondaryTextColor,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const Divider(thickness: 0.5, height: 1),
              const SizedBox(height: 24),

              // Markdown description content
              if (content.isNotEmpty)
                MarkdownBody(
                  data: content,
                  selectable: true,
                  onTapLink: (text, href, title) {
                    if (href != null) {
                      _launchUrl(context, href);
                    }
                  },
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: TextStyle(
                      fontSize: 14.5,
                      height: 1.6,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    ),
                    h1: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                      height: 1.5,
                    ),
                    h2: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                      height: 1.5,
                    ),
                    h3: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                      height: 1.5,
                    ),
                    listBullet: TextStyle(
                      fontSize: 14.5,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    ),
                    blockquote: TextStyle(
                      fontSize: 14.5,
                      fontStyle: FontStyle.italic,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                    ),
                    blockquoteDecoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      border: Border(
                        left: BorderSide(
                          color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                          width: 4,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
