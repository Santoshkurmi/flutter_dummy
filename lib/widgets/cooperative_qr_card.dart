import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../store/auth_store.dart';

class CooperativeQrCard extends StatelessWidget {
  final GlobalKey boundaryKey;
  final String data;
  final String label;
  final Color themeColor;
  final bool isDark;

  const CooperativeQrCard({
    super.key,
    required this.boundaryKey,
    required this.data,
    required this.label,
    required this.themeColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final coop = AuthStore().selectedCooperative;
    final coopName = (coop?['name'] ?? 'Bright Saving & Credit Co-operative').toString().toUpperCase();

    // Background decoration based on dark mode status
    final bgGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [themeColor.withValues(alpha: 0.05), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final cardBgColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return RepaintBoundary(
      key: boundaryKey,
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: bgGradient,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.08) : themeColor.withValues(alpha: 0.12),
              width: 2,
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Card Header: Logo and Cooperative Name
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Icon(
                    Icons.account_balance_rounded,
                    color: themeColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        coopName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          letterSpacing: 1.0,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // QR Code Container (Always White for scan reliability)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: QrImageView(
                data: data.isEmpty ? 'https://example.com' : data,
                version: QrVersions.auto,
                size: 200,
                gapless: false,
                eyeStyle: QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: themeColor,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (label.isNotEmpty) ...[
              Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white.withValues(alpha: 0.9) : const Color(0xFF1E293B),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.verified_user_rounded,
                  size: 14,
                  color: themeColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'SECURE DIGITAL SCANNABLE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
}
