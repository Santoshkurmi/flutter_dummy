import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/translation_service.dart';
import '../../store/auth_store.dart';
import 'home_tab.dart';
import '../accounts/combined_statement_page.dart';
import 'qr_tab.dart';
import 'notice_tab.dart';
import 'profile_tab.dart';
import '../auth/login_page.dart';

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
  bool get _isDarkMode => AuthStore().isDarkMode;

  final GlobalKey<QRTabState> _qrKey = GlobalKey<QRTabState>();
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshIndicatorKey.currentState?.show();
    });
    AuthStore().addListener(_onStateChange);
  }

  @override
  void dispose() {
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
      final summaryRes = await ApiService().getDashboardSummary();
      Map<String, dynamic>? accountsRes;
      try {
        accountsRes = await ApiService().getAccounts();
      } catch (_) {
        // Fallback: ignore accounts loading error so overview still displays
      }
      if (mounted) {
        setState(() {
          _summaryData = summaryRes['data'];
          _accountsData = accountsRes?['data'];
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

    try {
      await ApiService().logout();
    } catch (_) {}
    
    final store = AuthStore();
    final mobile = store.registeredMobile ?? store.mobile ?? '';
    await store.clearAuth();
    
    if (!mounted) return;
    
    // Explicitly navigate to LoginPage instead of the InitialRouter / Phone page
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage(mobileNumber: mobile)),
      (route) => false,
    );
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
                  borderRadius: BorderRadius.circular(8),
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

  void _cycleTheme() {
    final store = AuthStore();
    final next = store.isDarkMode ? 'light' : 'dark';
    store.setThemeMode(next);
  }

  void _onTabChanged(int newIndex) {
    final oldIndex = _currentIndex;

    // Deactivate QR camera when leaving QR tab
    if (oldIndex == 2 && newIndex != 2) {
      _qrKey.currentState?.stopCamera();
    }

    setState(() {
      _currentIndex = newIndex;
    });

    // Activate QR camera when entering QR tab
    if (newIndex == 2 && oldIndex != 2) {
      Future.delayed(const Duration(milliseconds: 50), () {
        _qrKey.currentState?.startCamera();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
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
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeTab(
              refreshIndicatorKey: _refreshIndicatorKey,
              summaryData: _summaryData,
              accountsData: _accountsData,
              showBalance: _showBalance,
              isDarkMode: _isDarkMode,
              isLoadingSummary: _isLoadingSummary,
              hasError: _hasError,
              onRefresh: _loadSummary,
              onThemeToggle: _cycleTheme,
              onLogout: _logout,
              onTabChange: _onTabChanged,
              onToggleBalanceVisibility: () {
                setState(() {
                  _showBalance = !_showBalance;
                });
              },
            ),
            const CombinedStatementPage(),
            QRTab(key: _qrKey, isDarkMode: _isDarkMode),
            NoticeTab(isDarkMode: _isDarkMode),
            ProfileTab(
              isDarkMode: _isDarkMode,
              onLogout: _logout,
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
