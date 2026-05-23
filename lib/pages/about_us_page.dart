import 'package:flutter/material.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
          'About Developer',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          children: [
            // Developer Logo / Heading Glow
            const SizedBox(height: 10),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF2563EB).withOpacity(0.08),
                    ),
                  ),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.code_rounded,
                      size: 32,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Bright Software Pvt. Ltd.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pioneering Cooperative Smart Banking Systems',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Description Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                'Bright Software is a premier fintech developer in Nepal, building high-security core banking platforms and mobile wallets for cooperatives. Engineered with robust end-to-end cryptographic architectures and system-aware UI, we ensure cooperative bank customers access digital banking safely.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 28),
            
            // Highlight Features section
            _buildSectionTitle('Engineered Security Specs', isDarkMode),
            const SizedBox(height: 12),
            
            _buildFeatureTile(
              title: 'Hardware Cryptographic Signatures',
              desc: 'Device linking isolated secure keys generated inside isolated system hardware Keystore environments.',
              icon: Icons.security_rounded,
              isDarkMode: isDarkMode,
            ),
            _buildFeatureTile(
              title: 'Dynamic Biometric Binding',
              desc: 'Passwordless PIN bypass utilizing platform-level secure strong biometric interfaces.',
              icon: Icons.fingerprint_rounded,
              isDarkMode: isDarkMode,
            ),
            _buildFeatureTile(
              title: 'Multi-Tenant Bank Engine',
              desc: 'Seamless dynamic lookup indexing for over 150 independent financial banking nodes.',
              icon: Icons.hub_rounded,
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 32),

            // Support Channels
            _buildSectionTitle('Developer Support Channels', isDarkMode),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildSupportChannel(
                  label: 'Website',
                  icon: Icons.language_rounded,
                  color: const Color(0xFF3B82F6),
                  isDarkMode: isDarkMode,
                ),
                const SizedBox(width: 10),
                _buildSupportChannel(
                  label: 'Support Call',
                  icon: Icons.call_rounded,
                  color: const Color(0xFF10B981),
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
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

  Widget _buildFeatureTile({
    required String title,
    required String desc,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportChannel({
    required String label,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Expanded(
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.04) : const Color(0xFFE2E8F0),
          ),
        ),
        child: InkWell(
          onTap: () {
            // Simulated contact clicks matching capacitor alerts
          },
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
