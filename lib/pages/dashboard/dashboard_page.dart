import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../services/translation_service.dart';
import '../../store/auth_store.dart';
import 'home_tab.dart';
import '../accounts/combined_statement_page.dart';
import 'qr_tab.dart';
import 'notice_tab.dart';
import 'profile_tab.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  bool _showBalance = false;
  bool _isLoadingSummary = true;
  bool _hasError = false;
  Map<String, dynamic>? _summaryData;
  Map<String, dynamic>? _accountsData;
  List<dynamic>? _cachedLedgerItems;
  DateTime? _lastLedgerFetchTime;
  late PageController _pageController;
  bool get _isDarkMode => AuthStore().isDarkMode;

  final GlobalKey<QRTabState> _qrKey = GlobalKey<QRTabState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshIndicatorKey.currentState?.show();
    });
    AuthStore().addListener(_onStateChange);
  }

  @override
  void dispose() {
    _pageController.dispose();
    AuthStore().removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSummary() async {
    if (mounted) {
      setState(() {
        _isLoadingSummary = true;
      });
    }
    try {
      final Future<Map<String, dynamic>> accountsFuture = ApiService().getAccounts();
      final Future<Map<String, dynamic>> ledgerFuture = ApiService().getAllAccountsLedger().catchError((_) => <String, dynamic>{});

      final results = await Future.wait([accountsFuture, ledgerFuture]);
      
      final Map<String, dynamic> accountsRes = results[0];
      final Map<String, dynamic> ledgerRes = results[1];

      if (mounted) {
        setState(() {
          _accountsData = accountsRes.isNotEmpty ? accountsRes['data'] : null;
          
          if (_accountsData != null) {
            double totalSavings = 0.0;
            double totalLoans = 0.0;
            double totalShares = 0.0;

            final savingsList = _accountsData!['savings'] as List<dynamic>?;
            if (savingsList != null) {
              for (final item in savingsList) {
                totalSavings += (item['balance'] as num?)?.toDouble() ?? 0.0;
              }
            }

            final loansList = _accountsData!['loans'] as List<dynamic>?;
            if (loansList != null) {
              for (final item in loansList) {
                totalLoans += (item['balance'] as num?)?.toDouble() ?? 0.0;
              }
            }

            final sharesList = _accountsData!['shares'] as List<dynamic>?;
            if (sharesList != null) {
              for (final item in sharesList) {
                totalShares += (item['balance'] as num?)?.toDouble() ?? 0.0;
              }
            }

            _summaryData = {
              'savings_balance': totalSavings,
              'loan_balance': totalLoans,
              'share_balance': totalShares,
            };
          } else {
            _summaryData = null;
          }

          if (ledgerRes['data'] != null) {
            _cachedLedgerItems = ledgerRes['data'];
            _lastLedgerFetchTime = DateTime.now();
          }
          _isLoadingSummary = false;
          _hasError = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _summaryData = null;
          _accountsData = null;
          _isLoadingSummary = false;
          _hasError = true;
        });
      }
    }
  }

  void _logout() async {
    final confirm = await _showLogoutConfirmation();
    if (confirm != true) return;

    // Trigger API call in the background without awaiting it
    ApiService().logout().catchError((_) => <String, dynamic>{});
    
    final store = AuthStore();
    await store.clearAuth();
    
    if (!mounted) return;
    
    // Pop all screens on top of the root route to avoid duplicate LoginPage
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _logoutAndExit() async {
    // Show a loading progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final isDark = AuthStore().isDarkMode;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                ),
                const SizedBox(height: 20),
                Text(
                  'Logging out...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we secure your session.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Call logout API and wait
    try {
      await ApiService().logout();
    } catch (_) {}

    // Clear local auth
    final store = AuthStore();
    await store.clearAuth();

    // Close loading dialog if mounted
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    // Exit app
    await SystemNavigator.pop();
  }

  Future<bool?> _showLogoutConfirmation() async {
    final isDark = AuthStore().isDarkMode;
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Confirm Logout',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to log out?',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool?> _showExitLogoutConfirmation() async {
    final isDark = AuthStore().isDarkMode;
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout & Exit',
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to log out of your session and exit the app?',
            style: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout & Exit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _cycleTheme() {
    final store = AuthStore();
    final next = store.isDarkMode ? 'light' : 'dark';
    store.setThemeMode(next);
  }

  void _onTabChanged(int newIndex) {
    _pageController.jumpToPage(newIndex);
  }

  Map<String, dynamic>? get _localizedAccountsData {
    if (_accountsData == null) return null;
    final isNepali = AuthStore().language == 'ne';
    final localized = <String, dynamic>{};
    for (final key in ['savings', 'loans', 'shares']) {
      final list = _accountsData![key] as List<dynamic>?;
      if (list != null) {
        localized[key] = list.map((item) {
          final acc = Map<String, dynamic>.from(item as Map);
          final String displayName = isNepali
              ? (acc['scheme_name_nepali'] ?? acc['scheme_name'] ?? 'Account')
              : (acc['scheme_name'] ?? 'Account');
          acc['name'] = displayName;
          acc['scheme'] = displayName;
          return acc;
        }).toList();
      }
    }
    return localized;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        
        if (_currentIndex == 0) {
          _showExitLogoutConfirmation().then((shouldLogoutAndExit) {
            if (shouldLogoutAndExit == true) {
              _logoutAndExit();
            }
          });
        } else {
          if (_currentIndex == 2) {
            final qrState = _qrKey.currentState;
            if (qrState != null && qrState.hasResult) {
              qrState.resetScanner();
              return;
            }
          }
          _onTabChanged(0);
        }
      },
      child: Scaffold(
        backgroundColor: _isDarkMode ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) {
            final oldIndex = _currentIndex;
            if (oldIndex == 2 && index != 2) {
              _qrKey.currentState?.stopCamera();
            }
            if (index == 2 && oldIndex != 2) {
              Future.delayed(const Duration(milliseconds: 50), () {
                _qrKey.currentState?.startCamera();
              });
            }
            setState(() {
              _currentIndex = index;
            });
          },
          children: [
            KeepAliveWrapper(
              child: HomeTab(
                refreshIndicatorKey: _refreshIndicatorKey,
                summaryData: _summaryData,
                accountsData: _localizedAccountsData,
                cachedLedgerItems: _cachedLedgerItems,
                showBalance: _showBalance,
                isDarkMode: _isDarkMode,
                isLoadingSummary: _isLoadingSummary,
                hasError: _hasError,
                onRefresh: _loadSummary,
                onThemeToggle: _cycleTheme,
                onLogout: _logout,
                onTabChange: (index) {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                  );
                },
                onToggleBalanceVisibility: () {
                  setState(() {
                    _showBalance = !_showBalance;
                  });
                },
              ),
            ),
            KeepAliveWrapper(
              child: CombinedStatementPage(
                currentIndex: _currentIndex,
                cachedLedgerItems: _cachedLedgerItems,
                lastLedgerFetchTime: _lastLedgerFetchTime,
                onLedgerFetched: (items) {
                  setState(() {
                    _cachedLedgerItems = items;
                    _lastLedgerFetchTime = DateTime.now();
                  });
                },
              ),
            ),
            KeepAliveWrapper(
              child: QRTab(key: _qrKey, isDarkMode: _isDarkMode),
            ),
            KeepAliveWrapper(
              child: NoticeTab(isDarkMode: _isDarkMode),
            ),
            KeepAliveWrapper(
              child: ProfileTab(
                isDarkMode: _isDarkMode,
                onLogout: _logout,
              ),
            ),
          ],
        ),
        bottomNavigationBar: Material(
          color: _isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: _isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
                  width: 1,
                ),
              ),
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _onTabChanged,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: _isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
              unselectedItemColor: const Color(0xFF64748B),
              selectedFontSize: 11,
              unselectedFontSize: 11,
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_rounded),
                  label: 'Home'.tr,
                  tooltip: '',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: 'Statement'.tr,
                  tooltip: '',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: 'Scan QR'.tr,
                  tooltip: '',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.campaign_rounded),
                  label: 'Notice'.tr,
                  tooltip: '',
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_rounded),
                  label: 'Profile'.tr,
                  tooltip: '',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
