import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/api_service.dart';
import '../store/auth_store.dart';
import 'account_details_page.dart';
import 'account_ledger_page.dart';
import 'settings_page.dart';
import 'about_us_page.dart';
import 'nepali_calendar_page.dart';
import 'register_member_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  bool _showBalance = false;
  bool _isLoadingSummary = true;
  Map<String, dynamic>? _summaryData;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    try {
      final res = await ApiService().getDashboardSummary();
      setState(() {
        _summaryData = res['data'];
        _isLoadingSummary = false;
      });
    } catch (_) {
      setState(() {
        _isLoadingSummary = false;
      });
    }
  }

  void _logout() async {
    try {
      await ApiService().logout();
    } catch (_) {}
    await AuthStore().clearAuth();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeTab(),
          _buildPaymentsTab(),
          _buildQRTab(),
          _buildNotificationsTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.06),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: const Color(0xFF60A5FA),
          unselectedItemColor: const Color(0xFF64748B),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded, color: Color(0xFF60A5FA)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payment_rounded),
              activeIcon: Icon(Icons.payment_rounded, color: Color(0xFF60A5FA)),
              label: 'Payments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_rounded),
              activeIcon: Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF60A5FA)),
              label: 'Scan QR',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_rounded),
              activeIcon: Icon(Icons.notifications_rounded, color: Color(0xFF60A5FA)),
              label: 'Alerts',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              activeIcon: Icon(Icons.person_rounded, color: Color(0xFF60A5FA)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: HOME ---
  Widget _buildHomeTab() {
    final profile = AuthStore().profile;
    final fullName = profile?['name'] ?? 'Sahakari User';
    final memberId = profile?['member_id'] ?? 'M-00000';
    
    final savingsBalance = _summaryData?['total_savings'] ?? 'Rs. 0.00';
    final recentTransactions = _summaryData?['recent_transactions'] as List?;

    return RefreshIndicator(
      onRefresh: _loadSummary,
      color: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFF0F172A),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          const SizedBox(height: 35),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Namaste, 🙏', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.5))),
                  Text(fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                child: Text(memberId, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF60A5FA))),
              ),
            ],
          ),
          const SizedBox(height: 24),

          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFFA825).withOpacity(0.15)),
                              child: const Icon(Icons.stars_rounded, color: Color(0xFFFFA825), size: 16),
                            ),
                            const SizedBox(width: 8),
                            const Text('Bright Savings Account', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                          ],
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF60A5FA), size: 20),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountDetailsPage())),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL ACCOUNT BALANCE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1)),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              _showBalance ? savingsBalance : '••••••••',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(_showBalance ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: const Color(0xFF60A5FA), size: 18),
                              onPressed: () => setState(() => _showBalance = !_showBalance),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _buildQuickActions(),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('RECENT TRANSACTIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 1.5)),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountDetailsPage())),
                child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF60A5FA))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _isLoadingSummary
              ? const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)))))
              : recentTransactions == null || recentTransactions.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text('No recent transactions found.', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13))))
                  : Column(
                      children: recentTransactions.map((tx) {
                        final isCredit = tx['type'] == 'credit' || tx['type'] == 'CR';
                        final amount = tx['amount'] ?? '0.00';
                        final amountStr = '${isCredit ? "+" : "-"} Rs. $amount';
                        final desc = tx['description'] ?? 'Transaction';
                        final dateStr = tx['date'] ?? '';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.04))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: isCredit ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFEF4444).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                    child: Icon(isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444), size: 14),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(desc, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                                      const SizedBox(height: 4),
                                      Text(dateStr, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ],
                              ),
                              Text(amountStr, style: TextStyle(fontWeight: FontWeight.bold, color: isCredit ? const Color(0xFF10B981) : Colors.white, fontSize: 14)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.list_alt_rounded, 'label': 'Statement', 'color': const Color(0xFF3B82F6)},
      {'icon': Icons.swap_horizontal_circle_rounded, 'label': 'Send Money', 'color': const Color(0xFF10B981)},
      {'icon': Icons.phone_android_rounded, 'label': 'Topup', 'color': const Color(0xFFF59E0B)},
      {'icon': Icons.receipt_long_rounded, 'label': 'Bill Pay', 'color': const Color(0xFFEC4899)},
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: actions.map((act) {
        return InkWell(
          onTap: () {
            if (act['label'] == 'Statement') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountDetailsPage()));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${act['label']} service initialized.')));
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: (act['color'] as Color).withOpacity(0.12), borderRadius: BorderRadius.circular(16), border: Border.all(color: (act['color'] as Color).withOpacity(0.2))),
                child: Icon(act['icon'] as IconData, color: act['color'] as Color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(act['label'] as String, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.payment_rounded, size: 64, color: Color(0xFF60A5FA)),
          const SizedBox(height: 16),
          const Text('Cooperative Bank Payments', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Transfer funds, pay utility bills, and pay loans instantly.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildQRTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_scanner_rounded, size: 64, color: Color(0xFF10B981)),
          const SizedBox(height: 16),
          const Text('QR Code Scanner', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Scan dynamic Fonepay or cooperative member QR codes to make payments instantly.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_active_rounded, size: 64, color: Color(0xFFF59E0B)),
          const SizedBox(height: 16),
          const Text('Alerts & Notifications', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text('Your secure notification inbox for transactions, deposits, and cooperative board updates.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final profile = AuthStore().profile;
    final coop = AuthStore().selectedCooperative;
    final name = profile?['name'] ?? 'Sahakari User';
    final mobile = profile?['mobile'] ?? '98XXXXXXXX';
    final coopName = coop?['name'] ?? 'Bright Saving & Credit Co-operative';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        const SizedBox(height: 35),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.04))),
          child: Column(
            children: [
              Container(width: 72, height: 72, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)])), child: Center(child: Text(name.substring(0, 1), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)))),
              const SizedBox(height: 16),
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 4),
              Text(mobile, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('COOPERATIVE IDENTITY', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        _profileOption(Icons.account_balance_rounded, 'Cooperative Bank', coopName),
        const SizedBox(height: 24),
        const Text('UTILITY SERVICES & PREFERENCES', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        _profileActionOption(Icons.settings_rounded, 'App Preferences', 'Configure alerts, daily limits and fingerprint setup', const SettingsPage()),
        _profileActionOption(Icons.app_registration_rounded, 'Self Registration', 'Become a member by filling self-registration wizard', const RegisterMemberPage()),
        _profileActionOption(Icons.calendar_month_rounded, 'Nepali Calendar BS 2083', 'View Bikram Sambat dates, Nepalese holidays and board runs', const NepaliCalendarPage()),
        _profileActionOption(Icons.info_outline_rounded, 'About Developer', 'Technical details, architecture and specs by Bright Software', const AboutUsPage()),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _logout,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444).withOpacity(0.15),
            foregroundColor: const Color(0xFFEF4444),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.logout_rounded), SizedBox(width: 10), Text('Logout Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _profileOption(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF60A5FA)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))])),
        ],
      ),
    );
  }

  Widget _profileActionOption(IconData icon, String title, String subtitle, Widget targetPage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => targetPage)),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF60A5FA)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 4), Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12))])),
              const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF64748B), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
