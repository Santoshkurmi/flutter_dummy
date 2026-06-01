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
  int _pointerCount = 0;

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
        builder: (_) => const AppPreferencesSetupPage(),
      ),
    );
  }

  void _showApiUrlDialog(BuildContext context) {
    final String initialUrl = AuthStore().customApiUrl ?? 'http://192.168.1.253:8000/api/mobile-banking/v1';
    
    String initialScheme = 'http';
    String initialHost = '192.168.1.253';
    String initialPort = '8000';
    String initialPath = '/api/mobile-banking/v1';

    try {
      final uri = Uri.parse(initialUrl);
      if (uri.hasScheme) {
        initialScheme = uri.scheme;
      }
      initialHost = uri.host;
      if (uri.hasPort) {
        initialPort = uri.port.toString();
      } else {
        initialPort = '';
      }
      initialPath = uri.path;
    } catch (_) {
      // Fallback defaults
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String dialogScheme = initialScheme;
        final hostController = TextEditingController(text: initialHost);
        final portController = TextEditingController(text: initialPort);
        final pathController = TextEditingController(text: initialPath);

        String getAssembledUrl(String scheme, String host, String port, String path) {
          final cleanHost = host.trim();
          final cleanPort = port.trim();
          var cleanPath = path.trim();
          if (cleanPath.isNotEmpty && !cleanPath.startsWith('/')) {
            cleanPath = '/$cleanPath';
          }
          if (cleanHost.isEmpty) return '';
          final portPart = cleanPort.isNotEmpty ? ':$cleanPort' : '';
          return '$scheme://$cleanHost$portPart$cleanPath';
        }

        return StatefulBuilder(
          builder: (context, setState) {
            final assembledUrl = getAssembledUrl(
              dialogScheme,
              hostController.text,
              portController.text,
              pathController.text,
            );

            return Dialog(
              backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title
                      Row(
                        children: [
                          const Icon(Icons.developer_board_rounded, color: Color(0xFF2563EB)),
                          const SizedBox(width: 10),
                          const Text(
                            'Developer Gateway',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Body/Description
                      const Text(
                        'Configure your API URL gateway endpoint below. Changes will persist across app restarts.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                      ),
                      const SizedBox(height: 16),
                      
                      // Protocol selection
                      const Text(
                        'Protocol',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  dialogScheme = 'http';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: dialogScheme == 'http'
                                      ? const Color(0xFF2563EB)
                                      : (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(10)),
                                  border: Border.all(
                                    color: dialogScheme == 'http'
                                        ? const Color(0xFF2563EB)
                                        : (isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'HTTP',
                                    style: TextStyle(
                                      color: dialogScheme == 'http' ? Colors.white : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  dialogScheme = 'https';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: dialogScheme == 'https'
                                      ? const Color(0xFF2563EB)
                                      : (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                                  border: Border.all(
                                    color: dialogScheme == 'https'
                                        ? const Color(0xFF2563EB)
                                        : (isDarkMode ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'HTTPS',
                                    style: TextStyle(
                                      color: dialogScheme == 'https' ? Colors.white : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Host Input
                      TextField(
                        controller: hostController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                        decoration: InputDecoration(
                          labelText: 'Host / IP Address',
                          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          hintText: 'e.g. 192.168.1.253',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          filled: true,
                          fillColor: isDarkMode ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Port & Path Inputs
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: portController,
                              onChanged: (_) => setState(() {}),
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                              decoration: InputDecoration(
                                labelText: 'Port',
                                labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                hintText: '8000',
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                filled: true,
                                fillColor: isDarkMode ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 4,
                            child: TextField(
                              controller: pathController,
                              onChanged: (_) => setState(() {}),
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                              decoration: InputDecoration(
                                labelText: 'API Path',
                                labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                hintText: '/api/mobile-banking/v1',
                                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                filled: true,
                                fillColor: isDarkMode ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Live assembled URL preview (Multi-line / Wrapping)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF020617) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Live Assembled API URL:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              assembledUrl.isNotEmpty ? assembledUrl : 'Invalid Host URL',
                              softWrap: true,
                              maxLines: null,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: assembledUrl.isNotEmpty
                                    ? (isDarkMode ? Colors.greenAccent : const Color(0xFF16A34A))
                                    : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              _pointerCount = 0;
                              Navigator.pop(context);
                            },
                            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                          ),
                          TextButton(
                            onPressed: () async {
                              await AuthStore().setCustomApiUrl(null);
                              _pointerCount = 0;
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('API Gateway reset to cooperative default successfully!'),
                                    backgroundColor: Color(0xFF10B981),
                                  ),
                                );
                              }
                            },
                            child: const Text('Reset', style: TextStyle(color: Color(0xFFEF4444))),
                          ),
                          TextButton(
                            onPressed: () async {
                              final url = assembledUrl;
                              if (url.isNotEmpty) {
                                await AuthStore().setCustomApiUrl(url);
                                _pointerCount = 0;
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Custom API Gateway redirected to: $url'),
                                      backgroundColor: const Color(0xFF2563EB),
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Text('Save Endpoint', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = AuthStore().isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF020617) : Colors.white,
      body: Listener(
        onPointerDown: (event) {
          _pointerCount++;
          if (_pointerCount == 3) {
            _showApiUrlDialog(context);
          }
        },
        onPointerUp: (event) {
          _pointerCount = (_pointerCount - 1).clamp(0, 5);
        },
        onPointerCancel: (event) {
          _pointerCount = 0;
        },
        child: Stack(
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
     ),
    );
  }
}
