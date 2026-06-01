import 'package:flutter/material.dart';
import '../../store/auth_store.dart';
import '../../services/translation_service.dart';
import '../accounts/account_details_page.dart';
import '../accounts/account_single_details_page.dart';
import '../services/nepali_calendar_page.dart';
import '../auth/register_member_page.dart';
import '../services/all_services_page.dart';
import '../../widgets/cooperative_account_card.dart';
import '../../store/notification_store.dart';
import 'notifications_tab.dart';
import '../accounts/transaction_receipt_page.dart';

class HomeTab extends StatefulWidget {
  final GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;
  final Map<String, dynamic>? summaryData;
  final Map<String, dynamic>? accountsData;
  final List<dynamic>? cachedLedgerItems;
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
    this.cachedLedgerItems,
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
    double d = 0.0;
    if (amt is num) {
      d = amt.toDouble();
    } else {
      final str = amt.toString().replaceAll(',', '');
      d = double.tryParse(str) ?? 0.0;
    }
    final formatted = d.toStringAsFixed(2);
    return AuthStore().language == 'ne'
        ? TranslationService.toNepaliNumbers(formatted)
        : formatted;
  }

  void _handleActionTap(BuildContext context, String label) {
    if (label == 'Accounts') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => AccountDetailsPage(initialAccountsData: widget.accountsData)));
    } else if (label == 'Statement') {
      widget.onTabChange(1); // Switches to the Statement bottom tab
    } else if (label == 'Calendar') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const NepaliCalendarPage()));
    } else if (label == 'Member Register') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterMemberPage()));
    }  else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label service not implemented yet.'),
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
    final recentTransactions = widget.cachedLedgerItems?.take(6).toList();

    final List<Map<String, dynamic>> cardsList = [];

    // Card 1: Overview
    cardsList.add({
      'isOverview': true,
      'title': 'Account Summary'.tr,
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
                  AnimatedBuilder(
                    animation: NotificationStore(),
                    builder: (context, _) {
                      final count = NotificationStore().unreadCount;
                      return Container(
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
                          icon: count > 0
                              ? Badge(
                                  label: Text(
                                    count.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: const Color(0xFFEF4444),
                                  child: Icon(
                                    Icons.notifications_rounded,
                                    color: widget.isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                    size: 18,
                                  ),
                                )
                              : Icon(
                                  Icons.notifications_rounded,
                                  color: widget.isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                                  size: 18,
                                ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NotificationsTab(
                                  isDarkMode: widget.isDarkMode,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
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
                        accountsData: widget.accountsData,
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
                onPressed: () => widget.onTabChange(1),
                child: Text(
                  'Show More'.tr,
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
                        final typeStr = (tx['type'] ?? '').toString().toUpperCase();
                        final isCredit = typeStr == 'CR' || typeStr == 'CREDIT';
                        final double amount = (tx['amount'] ?? 0.0).toDouble();
                        final amountStr = '${isCredit ? "+" : "-"} Rs. ${_formatAmount(amount)}';
                        final desc = tx['desc'] ?? tx['description'] ?? 'Transaction';
                        final dateStr = tx['nepaliDate'] ?? tx['date'] ?? '';
                        final refNo = tx['refNo'] ?? tx['reference_number'] ?? '';
                        final accountType = tx['accountType'] ?? 'savings';
                        final accountNo = tx['accountNo'] ?? 'N/A';

                        Color badgeBg;
                        Color badgeText;
                        String typeLabel;
                        if (accountType == 'savings') {
                          typeLabel = 'Savings';
                          badgeBg = widget.isDarkMode ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF);
                          badgeText = widget.isDarkMode ? const Color(0xFF818CF8) : const Color(0xFF4F46E5);
                        } else if (accountType == 'loans') {
                          typeLabel = 'Loan';
                          badgeBg = widget.isDarkMode ? const Color(0xFF451A03) : const Color(0xFFFEF2F2);
                          badgeText = widget.isDarkMode ? const Color(0xFFF87171) : const Color(0xFFDC2626);
                        } else if (accountType == 'shares') {
                          typeLabel = 'Shares';
                          badgeBg = widget.isDarkMode ? const Color(0xFF064E3B) : const Color(0xFFECFDF5);
                          badgeText = widget.isDarkMode ? const Color(0xFF34D399) : const Color(0xFF059669);
                        } else {
                          typeLabel = 'Account';
                          badgeBg = widget.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
                          badgeText = widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF475569);
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TransactionReceiptPage(
                                  transaction: Map<String, dynamic>.from(tx),
                                  accountType: accountType,
                                  accountNo: accountNo,
                                ),
                              ),
                            );
                          },
                          child: Container(
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
                              boxShadow: widget.isDarkMode
                                  ? []
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.015),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCredit
                                        ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                        : const Color(0xFFEF4444).withValues(alpha: 0.1),
                                  ),
                                  child: Icon(
                                    isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                    color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
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
                                      const SizedBox(height: 6),
                                      Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: badgeBg,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              typeLabel,
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w900,
                                                color: badgeText,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            accountNo,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: widget.isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        dateStr,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: widget.isDarkMode
                                              ? Colors.white.withValues(alpha: 0.6)
                                              : const Color(0xFF475569),
                                        ),
                                      ),
                                      if (refNo.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Ref: $refNo',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            color: widget.isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      amountStr,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                        fontSize: 14.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
        Navigator.push(context, MaterialPageRoute(builder: (_) => AccountDetailsPage(initialAccountsData: widget.accountsData)));
      } else {
        final List<Map<String, dynamic>> swipable = [];
        if (widget.accountsData != null) {
          final list = widget.accountsData![type] as List? ?? [];
          for (var acc in list) {
            swipable.add({'raw': acc, 'type': type});
          }
        }
        
        final index = swipable.indexWhere((a) {
          final raw = a['raw'] as Map;
          final aNo = raw['accNo'] ?? raw['account_no'];
          return aNo == cardData['accNo'];
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AccountSingleDetailsPage(
              account: Map<String, dynamic>.from(cardData['raw']),
              accountType: type,
              heroTag: 'card_${cardData['accNo']}',
              swipableAccounts: swipable,
              initialIndex: index >= 0 ? index : 0,
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
      heroTag: isOverview ? null : 'card_${cardData['accNo']}',
    );
  }


  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {'icon': Icons.send_rounded, 'label': 'Pay'},
      {'icon': Icons.arrow_downward_rounded, 'label': 'Deposit'},
       {'icon': Icons.arrow_downward_rounded, 'label': 'Internet'},
      {'icon': Icons.arrow_downward_rounded, 'label': 'Electricity'},
      {'icon': Icons.phone_android_rounded, 'label': 'TopUp'},
      {'icon': Icons.phone_android_rounded, 'label': 'Recharge'},
      {'icon': Icons.account_balance_wallet_rounded, 'label': 'Accounts'},
      {'icon': Icons.bolt_rounded, 'label': 'Utility'},
      {'icon': Icons.calendar_month_rounded, 'label': 'Calendar'},
      {'icon': Icons.newspaper_rounded, 'label': 'Notice'},
      {'icon': Icons.app_registration_rounded, 'label': 'Member Register'},
      {'icon': Icons.public_rounded, 'label': 'Remittance'},

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
          ElevatedButton(
            onPressed: () {
              widget.onRefresh();
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
                const Icon(Icons.refresh_rounded, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Try Again'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
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
