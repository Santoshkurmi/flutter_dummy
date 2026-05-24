import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import 'account_single_details_page.dart';
import '../widgets/cooperative_account_card.dart';

class AccountDetailsPage extends StatefulWidget {
  const AccountDetailsPage({super.key});

  @override
  State<AccountDetailsPage> createState() => _AccountDetailsPageState();
}

class _AccountDetailsPageState extends State<AccountDetailsPage> {
  List<dynamic> _savingsAccounts = [];
  List<dynamic> _loanAccounts = [];
  List<dynamic> _shareAccounts = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _activeFilter = 'all'; // all, savings, loans, shares
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      if (maxScroll > 0) {
        setState(() {
          _scrollProgress = (currentScroll / maxScroll).clamp(0.0, 1.0);
        });
      }
    }
  }

  String _formatAmount(dynamic amt) {
    if (amt == null) return '0.00';
    if (amt is num) {
      return amt.toStringAsFixed(2);
    }
    final str = amt.toString().replaceAll(',', '');
    final d = double.tryParse(str) ?? 0.0;
    return d.toStringAsFixed(2);
  }

  Future<void> _loadAccounts() async {
    try {
      final res = await ApiService().getAccounts();
      final data = res['data'] ?? {};
      
      setState(() {
        _savingsAccounts = data['savings'] ?? [];
        _loanAccounts = data['loans'] ?? [];
        _shareAccounts = data['shares'] ?? [];
        _isLoading = false;
        _hasError = false;
      });
    } catch (_) {
      setState(() {
        _savingsAccounts = [];
        _loanAccounts = [];
        _shareAccounts = [];
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Filter Logic
    List<dynamic> displayAccounts = [];
    if (_activeFilter == 'all' || _activeFilter == 'savings') {
      displayAccounts.addAll(_savingsAccounts.map((a) => {...a, 'type': 'savings'}));
    }
    if (_activeFilter == 'all' || _activeFilter == 'loans') {
      displayAccounts.addAll(_loanAccounts.map((a) => {...a, 'type': 'loans'}));
    }
    if (_activeFilter == 'all' || _activeFilter == 'shares') {
      displayAccounts.addAll(_shareAccounts.map((a) => {...a, 'type': 'shares'}));
    }

    final totalCount = _savingsAccounts.length + _loanAccounts.length + _shareAccounts.length;

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
          'My Accounts',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
                ),
              )
            : _hasError
                ? _buildErrorView(context, isDarkMode)
                : ListView(
                    padding: const EdgeInsets.only(top: 0, bottom: 24),
                    children: [
                      // Category Filter Bar with scroll indicators
                      const SizedBox(height: 10),
                      Stack(
                        children: [
                          SingleChildScrollView(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              children: [
                                _buildFilterPill('all', 'All', totalCount, isDarkMode),
                                const SizedBox(width: 10),
                                _buildFilterPill('savings', 'Savings', _savingsAccounts.length, isDarkMode),
                                const SizedBox(width: 10),
                                _buildFilterPill('loans', 'Loans', _loanAccounts.length, isDarkMode),
                                const SizedBox(width: 10),
                                _buildFilterPill('shares', 'Share Capital', _shareAccounts.length, isDarkMode),
                              ],
                            ),
                          ),
                          // Fade Overlay (on the right)
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            width: 30,
                            child: IgnorePointer(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      isDarkMode ? const Color(0xFF020617).withValues(alpha: 0.0) : Colors.white.withValues(alpha: 0.0),
                                      isDarkMode ? const Color(0xFF020617) : Colors.white,
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Custom progress tracker bar
                      const SizedBox(height: 10),
                      Center(
                        child: Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                left: _scrollProgress * 32.0,
                                top: 0,
                                bottom: 0,
                                width: 16,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Grouped Account Lists by Section
                      ..._buildAccountsList(isDarkMode),
                    ],
                  ),
      ),
    );
  }

  List<Widget> _buildAccountsList(bool isDarkMode) {
    final List<Widget> list = [];
    bool hasAnyAccount = false;

    // Savings Section
    if (_activeFilter == 'all' || _activeFilter == 'savings') {
      if (_savingsAccounts.isNotEmpty) {
        hasAnyAccount = true;
        list.add(_buildSectionHeader('Savings Accounts', const Color(0xFF2563EB), isDarkMode));
        for (var acc in _savingsAccounts) {
          list.add(_buildAccountCardWidget(acc, 'savings', isDarkMode));
        }
      }
    }

    // Loans Section
    if (_activeFilter == 'all' || _activeFilter == 'loans') {
      if (_loanAccounts.isNotEmpty) {
        hasAnyAccount = true;
        list.add(_buildSectionHeader('Loan Accounts', const Color(0xFFEF4444), isDarkMode));
        for (var acc in _loanAccounts) {
          list.add(_buildAccountCardWidget(acc, 'loans', isDarkMode));
        }
      }
    }

    // Shares Section
    if (_activeFilter == 'all' || _activeFilter == 'shares') {
      if (_shareAccounts.isNotEmpty) {
        hasAnyAccount = true;
        list.add(_buildSectionHeader('Share Capital Accounts', const Color(0xFF10B981), isDarkMode));
        for (var acc in _shareAccounts) {
          list.add(_buildAccountCardWidget(acc, 'shares', isDarkMode));
        }
      }
    }

    if (!hasAnyAccount) {
      list.add(
        Padding(
          padding: const EdgeInsets.only(top: 80, left: 20, right: 20),
          child: Center(
            child: Text(
              'No accounts found in this category.',
              style: TextStyle(
                color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return list;
  }

  Widget _buildSectionHeader(String title, Color color, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: isDarkMode ? const Color(0xFF64748B) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCardWidget(dynamic acc, String type, bool isDarkMode) {
    final double rawBalance = (acc['balance'] ?? 0.0).toDouble();
    final balance = 'Rs. ${_formatAmount(rawBalance)}';
    final accountNo = acc['accNo'] ?? acc['account_no'] ?? 'N/A';
    final name = acc['name'] ?? 'Account';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: CooperativeAccountCard(
        isOverview: false,
        accountType: type,
        title: acc['scheme'] ?? name,
        balance: balance,
        accountNo: accountNo,
        interestRate: acc['interest_rate'],
        shareCount: acc['share_count'],
        maturityDate: acc['maturity_date'],
        showBalance: true,
        isDarkMode: isDarkMode,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AccountSingleDetailsPage(
                account: Map<String, dynamic>.from(acc),
                accountType: type,
              ),
            ),
          ).then((_) => _loadAccounts()); // Refresh upon returning
        },
      ),
    );
  }

  Widget _buildFilterPill(String id, String label, int count, bool isDarkMode) {
    final isActive = _activeFilter == id;
    return InkWell(
      onTap: () {
        setState(() {
          _activeFilter = id;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF2563EB)
              : (isDarkMode ? const Color(0xFF0F172A).withValues(alpha: 0.4) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFF2563EB)
                : (isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: isActive ? Colors.white : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.2)
                    : (isDarkMode ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFCBD5E1)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: isActive ? Colors.white : (isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          // Animated Cartoon-like Network Error illustration
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.elasticOut,
            builder: (context, val, child) {
              return Transform.scale(
                scale: val,
                child: child,
              );
            },
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isDarkMode 
                      ? [const Color(0xFFEF4444).withValues(alpha: 0.2), const Color(0xFFF87171).withValues(alpha: 0.05)]
                      : [const Color(0xFFFEE2E2), const Color(0xFFFEF2F2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 60,
                    color: isDarkMode ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Something went wrong'.tr,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              'Failed to retrieve your cooperative accounts. Please go back and try opening the page again.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // "Go Back & Try Again" action button
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_back_rounded, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Go Back & Try Again'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}
