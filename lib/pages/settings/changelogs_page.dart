import 'package:flutter/material.dart';
import '../../data/changelog_data.dart';
import '../../services/translation_service.dart';
import '../../store/auth_store.dart';
import '../../services/theme_color_service.dart';

class ChangelogsPage extends StatelessWidget {
  const ChangelogsPage({super.key});

  String _formatNepaliNumbers(String input) {
    return AuthStore().language == 'ne'
        ? TranslationService.toNepaliNumbers(input)
        : input;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = context.isDarkMode;
    
    final primaryTextColor = colors.primaryText;
    final secondaryTextColor = colors.secondaryText;
    final cardBgColor = colors.cardBackground;
    final borderColor = colors.border;
    final accentColor = colors.accent;

    return Scaffold(
      backgroundColor: colors.scaffoldBackground,
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
          'Changelogs'.tr,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: primaryTextColor,
            fontSize: 20,
          ),
        ),
      ),
      body: FutureBuilder<void>(
        future: ChangelogData.load(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            );
          }

          final versionsList = ChangelogData.versions;

          return SafeArea(
            child: versionsList.isEmpty
                ? Center(
                    child: Text(
                      'No changelogs found.'.tr,
                      style: TextStyle(color: secondaryTextColor),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: versionsList.length,
                    itemBuilder: (context, index) {
                      final versionInfo = versionsList[index];
                      final isLast = index == versionsList.length - 1;

                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Timeline vertical line & indicator
                            Column(
                              children: [
                                // Dot indicator
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colors.scaffoldBackground,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: accentColor.withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      )
                                    ],
                                  ),
                                ),
                                // Line extending down
                                if (!isLast)
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: colors.border,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            
                            // Content card
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    color: cardBgColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: borderColor),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDarkMode 
                                            ? Colors.black.withValues(alpha: 0.1) 
                                            : Colors.black.withValues(alpha: 0.01),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Version & Date header
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${'Version'.tr} ${_formatNepaliNumbers(versionInfo.version)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 15,
                                              color: primaryTextColor,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: accentColor.withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _formatNepaliNumbers(versionInfo.date),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: accentColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Divider
                                      Container(
                                        height: 1,
                                        color: colors.border,
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Bullet logs
                                      ...versionInfo.logs.map((log) => Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                                            child: Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 6.0),
                                                  child: Container(
                                                    width: 5,
                                                    height: 5,
                                                    decoration: BoxDecoration(
                                                      color: colors.secondaryText,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    log.tr,
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      color: secondaryTextColor,
                                                      height: 1.45,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
