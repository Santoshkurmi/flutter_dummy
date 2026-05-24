import 'package:flutter/material.dart';
import '../../store/auth_store.dart';
import '../../services/translation_service.dart';
import '../account_details_page.dart';
import '../account_single_details_page.dart';
import '../nepali_calendar_page.dart';
import '../register_member_page.dart';
import '../all_services_page.dart';
import '../../widgets/cooperative_account_card.dart';

class HomeTab extends StatefulWidget {
  final GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;
  final Map<String, dynamic>? summaryData;
  final Map<String, dynamic>? accountsData;
  final bool showBalance;
  final bool isDarkMode;
  final bool isLoadingSummary;
  final bool hasError;
  final Future<void> Function() onRefresh;
  final VoidCallback onThemeToggle;
  final VoidCallback onLogout;
  final void Function(int) onTabChange;
  final VoidCallback onToggleBalanceVisibility;

  const HomeTab({
    super.key,
    this.refreshIndicatorKey,
    required this.summaryData,
    required this.accountsData,
    required this.showBalance,
    required this.isDarkMode,
    required this.isLoadingSummary,
    required this.hasError,
    required this.onRefresh,
    required this.onThemeToggle,
    required this.onLogout,
    required this.onTabChange,
    required this.onToggleBalanceVisibility,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  int _currentPageIndex = 0;
  double _dragOffset = 0.0;
  late AnimationController _swipeController;
  double _animationStartOffset = 0.0;
  double _animationTargetOffset = 0.0;
  bool _isAnimating = false;
  bool _isDismissal = false;
  int _dismissDirection = 0;
  bool _isDraggingCard = false;
  Offset? _startPointerPos;
  double _dragStartOffset = 0.0;
  bool _isPointerDragging = false;
  DateTime? _touchStartTime;
  DateTime? _lastHorizontalSwipeTime;
  late ScrollController _scrollController;

  int get _totalCardsCount {
    int count = 1; // Overview card
    if (widget.accountsData != null) {
      count += (widget.accountsData!['savings'] as List? ?? []).length;
      count += (widget.accountsData!['shares'] as List? ?? []).length;
      count += (widget.accountsData!['loans'] as List? ?? []).length;
    }
    return count;
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _swipeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addListener(() {
        setState(() {
          _dragOffset = Tween<double>(
            begin: _animationStartOffset,
            end: _animationTargetOffset,
          ).evaluate(_swipeController);
        });
      })..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (_isDismissal) {
            setState(() {
              int total = _totalCardsCount;
              _currentPageIndex = (_currentPageIndex + _dismissDirection) % total;
              if (_currentPageIndex < 0) {
                _currentPageIndex += total;
              }
              _dragOffset = 0.0;
              _isAnimating = false;
            });
          } else {
            setState(() {
              _dragOffset = 0.0;
              _isAnimating = false;
            });
          }
        }
      });
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _animateDismiss(int direction) {
    double screenWidth = MediaQuery.of(context).size.width;
    double pageWidth = screenWidth - 40.0;
    
    _isDismissal = true;
    _dismissDirection = direction; // 1 for left swipe (next card), -1 for right swipe (prev card)
    _animationStartOffset = _dragOffset;
    _animationTargetOffset = direction == 1 ? -pageWidth : pageWidth;
    
    _isAnimating = true;
    _swipeController.forward(from: 0.0);
  }

  void _animateSnapBack() {
    _isDismissal = false;
    _animationStartOffset = _dragOffset;
    _animationTargetOffset = 0.0;
    
    _isAnimating = true;
    _swipeController.forward(from: 0.0);
  }

  void _completeAnimationInstantly() {
    if (!_isAnimating) return;
    _swipeController.stop();
    if (_isDismissal) {
      int total = _totalCardsCount;
      _currentPageIndex = (_currentPageIndex + _dismissDirection) % total;
      if (_currentPageIndex < 0) {
        _currentPageIndex += total;
      }
    }
    _dragOffset = 0.0;
    _isAnimating = false;
  }

  void _handleDragEnd(double primaryVelocity) {
    final bool didSwipe = _isDraggingCard;
    
    setState(() {
      _isPointerDragging = false;
      _isDraggingCard = false;
    });
    
    if (_isAnimating) return;
    
    final velocity = primaryVelocity.abs();
    
    if (_dragOffset.abs() > 80.0 || (didSwipe && velocity > 400.0)) {
      _animateDismiss(_dragOffset > 0 ? -1 : 1);
      _lastHorizontalSwipeTime = DateTime.now();
    } else {
      _animateSnapBack();
      if (didSwipe) {
        _lastHorizontalSwipeTime = DateTime.now();
      }
    }
    
    _startPointerPos = null;
  }

  void _handleDragCancel() {
    setState(() {
      _isPointerDragging = false;
      _isDraggingCard = false;
    });
    if (!_isAnimating) {
      _animateSnapBack();
    }
    _startPointerPos = null;
  }

  double get _currentPage {
    if (!mounted) return 0.0;
    double screenWidth = MediaQuery.of(context).size.width;
    double pageWidth = screenWidth - 40.0;
    double progress = (pageWidth > 0) ? (_dragOffset / pageWidth) : 0.0;
    return _currentPageIndex - progress;
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

  void _handleActionTap(BuildContext context, String label) {
    if (label == 'Statement' || label == 'Savings') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountDetailsPage()));
    } else if (label == 'Calendar') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const NepaliCalendarPage()));
    } else if (label == 'Ledger') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountDetailsPage()));
    } else if (label == 'Self Register') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterMemberPage()));
    } else if (label == 'Utility' || label == 'Payment' || label == 'Send Money') {
      widget.onTabChange(1); // Payments Tab
    } else if (label == 'Scan QR' || label == 'QR Scan') {
      widget.onTabChange(2); // Scan QR Tab
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label service initialized.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    final profile = AuthStore().profile;
    final firstName = profile?['member_first_name'] ?? (profile?['member_name']?.toString().split(' ').first) ?? 'User';
    
    final savingsVal = _formatAmount(widget.summaryData?['savings_balance']);
    final shareVal = _formatAmount(widget.summaryData?['share_balance']);
    final loanVal = _formatAmount(widget.summaryData?['loan_balance']);

    final savingsBalance = 'Rs. $savingsVal';
    final shareBalance = 'Rs. $shareVal';
    final loanBalance = 'Rs. $loanVal';
    final recentTransactions = widget.summaryData?['recent_transactions'] as List?;

    final List<Map<String, dynamic>> cardsList = [];

    // Card 1: Overview
    cardsList.add({
      'isOverview': true,
      'title': 'Bright Savings Account'.tr,
      'balance': savingsBalance,
      'savingsBalance': savingsBalance,
      'loanBalance': loanBalance,
      'shareBalance': shareBalance,
    });

    if (widget.accountsData != null) {
      final savingsList = widget.accountsData!['savings'] as List? ?? [];
      final sharesList = widget.accountsData!['shares'] as List? ?? [];
      final loansList = widget.accountsData!['loans'] as List? ?? [];

      for (var acc in savingsList) {
        cardsList.add({
          'isOverview': false,
          'type': 'savings',
          'scheme': acc['scheme'] ?? 'Savings Account',
          'title': acc['name'] ?? 'Savings Account',
          'accNo': acc['accNo'] ?? 'N/A',
          'balance': 'Rs. ${_formatAmount(acc['balance'])}',
          'interest_rate': acc['interest_rate'],
          'accrued_interest': acc['accrued_interest'],
          'raw': acc,
        });
      }

      for (var acc in sharesList) {
        cardsList.add({
          'isOverview': false,
          'type': 'shares',
          'scheme': 'Member Shares',
          'title': acc['name'] ?? 'Share Account',
          'accNo': acc['accNo'] ?? 'N/A',
          'balance': 'Rs. ${_formatAmount(acc['balance'])}',
          'share_count': acc['share_count'],
          'raw': acc,
        });
      }

      for (var acc in loansList) {
        cardsList.add({
          'isOverview': false,
          'type': 'loans',
          'scheme': acc['scheme'] ?? 'Loan Account',
          'title': acc['name'] ?? 'Loan Account',
          'accNo': acc['accNo'] ?? 'N/A',
          'balance': 'Rs. ${_formatAmount(acc['balance'])}',
          'interest_rate': acc['interest_rate'],
          'maturity_date': acc['maturity_date'],
          'raw': acc,
        });
      }
    }

    if (_currentPageIndex >= cardsList.length) {
      _currentPageIndex = 0;
    }

    return RefreshIndicator(
      key: widget.refreshIndicatorKey,
      onRefresh: widget.onRefresh,
      color: const Color(0xFF2563EB),
      backgroundColor: widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
      child: ListView(
        controller: _scrollController,
        physics: _isDraggingCard ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          const SizedBox(height: 35),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Namaste, 🙏',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.5) : Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    firstName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [

                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEFF6FF),
                      border: Border.all(
                        color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFDBEAFE),
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        widget.showBalance ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: widget.isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                        size: 16,
                      ),
                      onPressed: widget.onToggleBalanceVisibility,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEFF6FF),
                      border: Border.all(
                        color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFDBEAFE),
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        widget.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: widget.isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                        size: 16,
                      ),
                      onPressed: widget.onThemeToggle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isDarkMode ? const Color(0xFF1C1017) : const Color(0xFFFEF2F2),
                      border: Border.all(
                        color: widget.isDarkMode ? const Color(0xFF3B1A1A) : const Color(0xFFFEE2E2),
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.power_settings_new_rounded,
                        color: Color(0xFFEF4444),
                        size: 16,
                      ),
                      onPressed: widget.onLogout,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (widget.hasError)
            _buildErrorView(context, widget.isDarkMode)
          else ...[
            const SizedBox(height: 20),

            // Render Swipable Stack (Gentle Slide Stack with correct Z-order layering)
            SizedBox(
              height: 190,
              child: ClipRRect(
                clipBehavior: Clip.none,
                child: cardsList.length <= 1
                    ? _buildCardItem(context, cardsList.first)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          double pageWidth = constraints.maxWidth;
                          
                          int nextPageIndex = _dragOffset < 0
                              ? (_currentPageIndex + 1) % cardsList.length
                              : (_currentPageIndex - 1 + cardsList.length) % cardsList.length;

                          double progress = (pageWidth > 0) ? (_dragOffset.abs() / pageWidth).clamp(0.0, 1.0) : 0.0;
                          double scale = 0.95 + progress * 0.05;

                          final Matrix4 bottomMatrix = Matrix4.identity()
                            ..scaleByDouble(scale, scale, 1.0, 1.0);

                          final Matrix4 topMatrix = Matrix4.identity()
                            ..translateByDouble(_dragOffset, 0.0, 0.0, 1.0);

                          return Listener(
                            onPointerDown: (event) {
                              if (_isAnimating) {
                                setState(() {
                                  _completeAnimationInstantly();
                                });
                              }
                            },
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragStart: (details) {
                                setState(() {
                                  _isDraggingCard = true;
                                });
                                _startPointerPos = details.globalPosition;
                                _dragStartOffset = _dragOffset;
                                _touchStartTime = DateTime.now();
                                _isPointerDragging = true;
                              },
                              onHorizontalDragUpdate: (details) {
                                if (_isPointerDragging && _startPointerPos != null) {
                                  final delta = details.globalPosition - _startPointerPos!;
                                  setState(() {
                                    _dragOffset = _dragStartOffset + delta.dx;
                                  });
                                }
                              },
                              onHorizontalDragEnd: (details) {
                                _handleDragEnd(details.primaryVelocity ?? 0.0);
                              },
                              onHorizontalDragCancel: () {
                                _handleDragCancel();
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Bottom Card (Next Card expanding scale underneath)
                                  Positioned.fill(
                                    child: Transform(
                                      transform: bottomMatrix,
                                      alignment: Alignment.center,
                                      child: IgnorePointer(
                                        child: _buildCardItem(context, cardsList[nextPageIndex]),
                                      ),
                                    ),
                                  ),
                                  // Top Card (Active Card sliding horizontally - ALWAYS on top)
                                  Positioned.fill(
                                    child: Transform(
                                      transform: topMatrix,
                                      alignment: Alignment.center,
                                      child: _buildCardItem(context, cardsList[_currentPageIndex]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            
            // Dots indicator
            if (cardsList.length > 1) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(cardsList.length, (index) {
                  double difference = index - _currentPage;
                  double activeRatio = (1.0 - difference.abs().clamp(0.0, 1.0));
                  double width = 6.0 + (14.0 * activeRatio);

                  // Color based on the card gradient
                  final card = cardsList[index];
                  Color cardAccentColor;
                  if (card['isOverview'] == true) {
                    cardAccentColor = const Color(0xFF2563EB); // Blue
                  } else {
                    final type = card['type'] as String?;
                    if (type == 'savings') {
                      cardAccentColor = const Color(0xFF6366F1); // Indigo
                    } else if (type == 'shares') {
                      cardAccentColor = const Color(0xFF10B981); // Emerald/Teal
                    } else if (type == 'loans') {
                      cardAccentColor = const Color(0xFFF43F5E); // Rose
                    } else {
                      cardAccentColor = const Color(0xFF2563EB);
                    }
                  }

                  final inactiveColor = widget.isDarkMode
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.15);
                  final dotColor = Color.lerp(inactiveColor, cardAccentColor, activeRatio) ?? cardAccentColor;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: dotColor,
                    ),
                  );
                }),
              ),
            ],
            const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUICK ACTIONS'.tr,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? const Color(0xFF64748B) : const Color(0xFF475569),
                  letterSpacing: 1.5,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AllServicesPage(
                        isDarkMode: widget.isDarkMode,
                        onTabChange: widget.onTabChange,
                      ),
                    ),
                  );
                },
                child: Text(
                  'View All'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          _buildQuickActions(context),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECENT TRANSACTIONS'.tr,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: widget.isDarkMode ? const Color(0xFF64748B) : const Color(0xFF475569),
                  letterSpacing: 1.5,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountDetailsPage())),
                child: Text(
                  'View All'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: widget.isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          widget.isLoadingSummary
              ? const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)))))
              : recentTransactions == null || recentTransactions.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text('No recent transactions found.', style: TextStyle(color: widget.isDarkMode ? Colors.white.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.4), fontSize: 13))))
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
                          decoration: BoxDecoration(
                            color: widget.isDarkMode ? const Color(0xFF0F172A) : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: widget.isDarkMode
                                  ? Colors.white.withValues(alpha: 0.04)
                                  : Colors.black.withValues(alpha: 0.04),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: isCredit ? const Color(0xFF10B981).withValues(alpha: 0.1) : const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                    child: Icon(isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444), size: 14),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        desc,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dateStr,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: widget.isDarkMode ? const Color(0xFF64748B) : const Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Text(
                                amountStr,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isCredit ? const Color(0xFF10B981) : (widget.isDarkMode ? Colors.white : const Color(0xFF1E293B)),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardItem(BuildContext context, Map<String, dynamic> cardData) {
    final isOverview = cardData['isOverview'] as bool;
    final String type = cardData['type'] ?? 'overview';

    void onTapArrow() {
      if (isOverview) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountDetailsPage()));
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AccountSingleDetailsPage(
              account: Map<String, dynamic>.from(cardData['raw']),
              accountType: type,
            ),
          ),
        );
      }
    }

    return CooperativeAccountCard(
      isOverview: isOverview,
      accountType: type,
      title: cardData['title'],
      balance: cardData['balance'],
      accountNo: cardData['accNo'] ?? '',
      interestRate: cardData['interest_rate'],
      shareCount: cardData['share_count'],
      maturityDate: cardData['maturity_date'],
      loanBalance: cardData['loanBalance'],
      shareBalance: cardData['shareBalance'],
      showBalance: widget.showBalance,
      isDarkMode: widget.isDarkMode,
      onTap: onTapArrow,
    );
  }


  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'icon': Icons.send_rounded, 'label': 'Send Money'},
      {'icon': Icons.arrow_downward_rounded, 'label': 'Receive'},
      {'icon': Icons.receipt_long_rounded, 'label': 'Statement'},
      {'icon': Icons.savings_rounded, 'label': 'Deposit'},
      {'icon': Icons.menu_book_rounded, 'label': 'Ledger'},
      {'icon': Icons.pie_chart_rounded, 'label': 'Share'},
      {'icon': Icons.business_center_rounded, 'label': 'Loan'},
      {'icon': Icons.calendar_month_rounded, 'label': 'Calendar'},
      {'icon': Icons.bolt_rounded, 'label': 'Utility'},
      {'icon': Icons.newspaper_rounded, 'label': 'Notice'},
      {'icon': Icons.calculate_rounded, 'label': 'Calculator'},
      {'icon': Icons.app_registration_rounded, 'label': 'Self Register'},
    ];

    final Color containerColor = widget.isDarkMode 
        ? Colors.white.withValues(alpha: 0.05) 
        : const Color(0xFFEFF6FF);
    final Color borderColor = widget.isDarkMode 
        ? Colors.white.withValues(alpha: 0.08) 
        : const Color(0xFFDBEAFE);
    final Color iconColor = widget.isDarkMode 
        ? const Color(0xFF60A5FA) 
        : const Color(0xFF2563EB);

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.9,
      children: actions.map((act) {
        return InkWell(
          onTap: () => _handleActionTap(context, act['label'] as String),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: containerColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Icon(act['icon'] as IconData, color: iconColor, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                (act['label'] as String).tr,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorView(BuildContext context, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 70),
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
                  // Animated glowing rings
                  _ErrorPulseRing(delay: 0, isDarkMode: isDarkMode),
                  _ErrorPulseRing(delay: 500, isDarkMode: isDarkMode),
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 60,
                    color: isDarkMode ? const Color(0xFFF87171) : const Color(0xFFEF4444),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Connection Failed'.tr,
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
              'We had trouble communicating with the cooperative servers. Please check your internet connection.'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 40),
          // Swipe to reload indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swap_vert_rounded,
                  size: 16,
                  color: isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                ),
                const SizedBox(width: 8),
                Text(
                  'Swipe down to reload'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ErrorPulseRing extends StatefulWidget {
  final int delay;
  final bool isDarkMode;
  const _ErrorPulseRing({required this.delay, required this.isDarkMode});

  @override
  State<_ErrorPulseRing> createState() => _ErrorPulseRingState();
}

class _ErrorPulseRingState extends State<_ErrorPulseRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 140 * _controller.value,
          height: 140 * _controller.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: (widget.isDarkMode ? const Color(0xFFEF4444) : const Color(0xFFF87171))
                  .withValues(alpha: (1.0 - _controller.value) * 0.3),
              width: 1.5,
            ),
          ),
        );
      },
    );
  }
}
