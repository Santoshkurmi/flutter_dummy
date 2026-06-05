import 'dart:async';
import 'package:flutter/material.dart';
import '../../store/auth_store.dart';
import '../../services/translation_service.dart';
import 'app_preferences_setup_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoplayTimer;
  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Smart Banking',
      'subtitle': 'Manage your wealth with intelligence',
      'description': 'Bright Bank brings you a premium, intuitive way to track your savings and manage transactions instantly.',
      'icon': Icons.account_balance_wallet_rounded,
      'colors': [Color(0xFF2563EB), Color(0xFF4338CA)],
      'iconBg': Color(0xFF2563EB),
    },
    {
      'title': 'Ironclad Security',
      'subtitle': 'Your safety is our priority',
      'description': 'With multi-factor authentication and device-level encryption, your funds are safer than ever before.',
      'icon': Icons.shield_rounded,
      'colors': [Color(0xFF059669), Color(0xFF0F766E)],
      'iconBg': Color(0xFF059669),
    },
    {
      'title': 'Instant Power',
      'subtitle': 'Banking at the speed of life',
      'description': 'Transfer money, pay bills, and get real-time alerts. Experience the fastest banking app in Nepal.',
      'icon': Icons.bolt_rounded,
      'colors': [Color(0xFF9333EA), Color(0xFFBE123C)],
      'iconBg': Color(0xFF9333EA),
    }
  ];

  @override
  void initState() {
    super.initState();
    _startAutoplay();
  }

  @override
  void dispose() {
    _autoplayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoplay() {
    _autoplayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_currentPage < _slides.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          );
      }
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _finishOnboarding() {
    _autoplayTimer?.cancel();
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'AppPreferencesSetupPage'),
        builder: (_) => const AppPreferencesSetupPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AuthStore().isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF020617) : Colors.white,
      body: Stack(
          children: [
          // Dynamic Radial Blur Glow Background behind current slide
          AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double page = 0.0;
              if (_pageController.hasClients) {
                page = _pageController.page ?? 0.0;
              } else {
                page = _currentPage.toDouble();
              }

              // Simple color interpolation for background glows
              int activeIdx = page.floor();
              int nextIdx = (activeIdx + 1).clamp(0, _slides.length - 1);
              double ratio = page - activeIdx;

              final activeColors = _slides[activeIdx]['colors'] as List<Color>;
              final nextColors = _slides[nextIdx]['colors'] as List<Color>;

              final primaryGlow = Color.lerp(activeColors[0], nextColors[0], ratio) ?? activeColors[0];
              final secondaryGlow = Color.lerp(activeColors[1], nextColors[1], ratio) ?? activeColors[1];

              return Positioned(
                top: -150,
                left: -150,
                right: -150,
                child: Container(
                  height: 600,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        primaryGlow.withValues(alpha: isDarkMode ? 0.15 : 0.08),
                        secondaryGlow.withValues(alpha: isDarkMode ? 0.05 : 0.02),
                        Colors.transparent,
                      ],
                      radius: 0.8,
                    ),
                  ),
                ),
              );
            },
          ),

          // Main Onboarding Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification notification) {
                      if (notification is UserScrollNotification) {
                        if (_autoplayTimer != null && _autoplayTimer!.isActive) {
                          _autoplayTimer?.cancel();
                        }
                      }
                      return false;
                    },
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _slides.length,
                      itemBuilder: (context, index) {
                        final slide = _slides[index];
                        final gradientColors = slide['colors'] as List<Color>;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // 30% Reduced Glassmorphic Icon controls
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 98,
                                    height: 98,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: (slide['iconBg'] as Color).withValues(alpha: 0.12),
                                    ),
                                  ),
                                  Container(
                                    width: 68,
                                    height: 68,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: gradientColors,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (slide['iconBg'] as Color).withValues(alpha: 0.2),
                                          blurRadius: 15,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      slide['icon'] as IconData,
                                      size: 32,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 40),

                              // Subtitle
                              Text(
                                (slide['subtitle'] as String).tr.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.2,
                                  color: slide['iconBg'] as Color,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Title
                              Text(
                                (slide['title'] as String).tr,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Description
                              Text(
                                (slide['description'] as String).tr,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Pagination & Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Smooth Custom Fluid Indicators (Offset-Linked Animation via PageController)
                      AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double page = 0.0;
                          if (_pageController.hasClients) {
                            page = _pageController.page ?? 0.0;
                          } else {
                            page = _currentPage.toDouble();
                          }
                          
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_slides.length, (index) {
                              double distance = (index - page).abs();
                              double activeRatio = (1.0 - distance.clamp(0.0, 1.0));
                              double width = 6.0 + (18.0 * activeRatio);
                              final colors = _slides[index]['colors'] as List<Color>;

                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                height: 6,
                                width: width,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  gradient: activeRatio > 0.05
                                      ? LinearGradient(
                                          colors: colors.map((c) => c.withValues(alpha: activeRatio)).toList(),
                                        )
                                      : null,
                                  color: activeRatio <= 0.05
                                      ? (isDarkMode ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.15))
                                      : null,
                                ),
                              );
                            }),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Get Started Action Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: isDarkMode 
                                  ? Colors.black.withValues(alpha: 0.1) 
                                  : const Color(0xFF2563EB).withValues(alpha: 0.15),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            )
                          ]
                        ),
                        child: ElevatedButton(
                          onPressed: _finishOnboarding,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDarkMode ? Colors.white : const Color(0xFF2563EB),
                            foregroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Get Started'.tr,
                                style: const TextStyle(
                                  fontSize: 16,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
