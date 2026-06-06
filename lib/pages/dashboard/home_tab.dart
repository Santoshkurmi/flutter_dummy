import 'package:flutter/material.dart';
import '../../store/auth_store.dart';
import '../../services/translation_service.dart';
import '../../services/theme_color_service.dart';
import '../accounts/account_details_page.dart';
import '../accounts/account_single_details_page.dart';
import '../services/nepali_calendar_page.dart';
import '../auth/register_member_page.dart';
import '../services/all_services_page.dart';
import '../../widgets/cooperative_account_card.dart';
import '../../store/notification_store.dart';
import 'notifications_tab.dart';
import '../accounts/transaction_receipt_page.dart';
import '../../store/notice_store.dart';
import 'notice_detail_page.dart';
import '../settings/member_details_page.dart';
import '../../widgets/error_state_view.dart';

class HomeTab extends StatefulWidget {
  final GlobalKey<RefreshIndicatorState>? refreshIndicatorKey;
  final Map<String, dynamic>? summaryData;
  final Map<String, dynamic>? accountsData;
  final List<dynamic>? cachedLedgerItems;
  final bool showBalance;
  final bool isDarkMode;
  final bool isLoadingSummary;
  final bool hasError;
  final String? errorMessage;
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
    this.errorMessage,
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
  int _currentNoticeIndex = 0;
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
  late ScrollController _scrollController;
  Offset? _sliderDownPos;
  DateTime? _sliderDownTime;

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
    NoticeStore().addListener(_onNoticeStoreChange);
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
    NoticeStore().removeListener(_onNoticeStoreChange);
    _swipeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onNoticeStoreChange() {
    if (mounted) setState(() {});
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
    } else {
      _animateSnapBack();
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
      Navigator.push(context, MaterialPageRoute(settings: const RouteSettings(name: 'AccountDetailsPage'), builder: (_) => AccountDetailsPage(initialAccountsData: widget.accountsData)));
    } else if (label == 'Statement') {
      widget.onTabChange(1); // Switches to the Statement bottom tab
    } else if (label == 'Calendar') {
      Navigator.push(context, MaterialPageRoute(settings: const RouteSettings(name: 'NepaliCalendarPage'), builder: (_) => const NepaliCalendarPage()));
    } else if (label == 'Member Register') {
      Navigator.push(context, MaterialPageRoute(settings: const RouteSettings(name: 'RegisterMemberPage'), builder: (_) => const RegisterMemberPage()));
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
    final colors = context.colors;
    final isDarkMode = context.isDarkMode;

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
      color: colors.accent,
      backgroundColor: colors.cardBackground,
      child: ListView(
        controller: _scrollController,
        physics: _isDraggingCard ? const NeverScrollableScrollPhysics() : null,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        children: [
          const SizedBox(height: 35),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'MemberDetailsPage'),
                      builder: (_) => const MemberDetailsPage(),
                    ),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Namaste, 🙏'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.secondaryText,
                      ),
                    ),
                    Text(
                      firstName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
  
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.quickActionBackground,
                      border: Border.all(
                        color: colors.quickActionBorder,
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        widget.showBalance ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: colors.quickActionIcon,
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
                      color: colors.quickActionBackground,
                      border: Border.all(
                        color: colors.quickActionBorder,
                      ),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: colors.quickActionIcon,
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
                          color: colors.quickActionBackground,
                          border: Border.all(
                            color: colors.quickActionBorder,
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
                                    color: colors.quickActionIcon,
                                    size: 18,
                                  ),
                                )
                              : Icon(
                                  Icons.notifications_rounded,
                                  color: colors.quickActionIcon,
                                  size: 18,
                                ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                settings: const RouteSettings(name: 'NotificationsTab'),
                                builder: (_) => NotificationsTab(
                                  isDarkMode: isDarkMode,
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
                  double page = _currentPage % cardsList.length;
                  if (page < 0) {
                    page += cardsList.length;
                  }
                  double diff = index - page;
                  if (diff > cardsList.length / 2.0) {
                    diff -= cardsList.length;
                  } else if (diff < -cardsList.length / 2.0) {
                    diff += cardsList.length;
                  }
                  double distance = diff.abs();
                  double activeRatio = (1.0 - distance.clamp(0.0, 1.0));
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

                  final inactiveColor = colors.border;
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
            const SizedBox(height: 14),
            _buildNoticeSlider(context),
            const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QUICK ACTIONS'.tr,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colors.secondaryText,
                  letterSpacing: 1.5,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'AllServicesPage'),
                      builder: (_) => AllServicesPage(
                        isDarkMode: isDarkMode,
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
                    color: colors.accent,
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
                  color: colors.secondaryText,
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
                    color: colors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          widget.isLoadingSummary
              ? Center(child: Padding(padding: const EdgeInsets.all(24.0), child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(colors.accent))))
              : recentTransactions == null || recentTransactions.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text('No recent transactions found.'.tr, style: TextStyle(color: colors.secondaryText, fontSize: 13))))
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
                          typeLabel = 'Savings'.tr;
                          badgeBg = colors.infoBadgeBg;
                          badgeText = colors.infoBadgeText;
                        } else if (accountType == 'loans') {
                          typeLabel = 'Loan'.tr;
                          badgeBg = colors.errorBadgeBg;
                          badgeText = colors.errorBadgeText;
                        } else if (accountType == 'shares') {
                          typeLabel = 'Shares'.tr;
                          badgeBg = colors.successBadgeBg;
                          badgeText = colors.successBadgeText;
                        } else {
                          typeLabel = 'Account'.tr;
                          badgeBg = colors.cardBackground;
                          badgeText = colors.secondaryText;
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                settings: const RouteSettings(name: 'TransactionReceiptPage'),
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
                              color: colors.cardBackground,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: colors.border,
                              ),
                              boxShadow: isDarkMode
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
                                          color: colors.primaryText,
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
                                              color: colors.secondaryText,
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
                                          color: colors.secondaryText,
                                        ),
                                      ),
                                      if (refNo.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          'Ref: $refNo',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            color: colors.secondaryText,
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
        Navigator.push(context, MaterialPageRoute(settings: const RouteSettings(name: 'AccountDetailsPage'), builder: (_) => AccountDetailsPage(initialAccountsData: widget.accountsData)));
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
            settings: const RouteSettings(name: 'AccountSingleDetailsPage'),
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

    final colors = context.colors;
    final Color containerColor = colors.quickActionBackground;
    final Color borderColor = colors.quickActionBorder;
    final Color iconColor = colors.quickActionIcon;

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
                  color: colors.primaryText,
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

  int _lastNoticeTapTime = 0;

  void _handleNoticeTap(Map<String, dynamic> notice, int id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastNoticeTapTime < 500) {
      return;
    }
    _lastNoticeTapTime = now;
    NoticeStore().markAsRead(id);
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: 'NoticeDetailPage'),
        builder: (context) => NoticeDetailPage(
          notice: notice,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    );
  }

  Widget _buildNoticeSlider(BuildContext context) {
    final colors = context.colors;
    final isDarkMode = context.isDarkMode;

    // Helper to determine if notice should show in the slider
    bool shouldShowNotice(Map n) {
      final id = n['id'] as int? ?? 0;
      if (id <= 0) return false;

      // Show if not read in previous sessions
      if (!NoticeStore().initiallyReadNoticeIds.contains(id)) {
        return true;
      }

      // Or show if created today (even if already read)
      final createdAtStr = n['created_at']?.toString();
      if (createdAtStr != null) {
        try {
          final dateTime = DateTime.parse(createdAtStr).toLocal();
          final now = DateTime.now();
          if (dateTime.year == now.year &&
              dateTime.month == now.month &&
              dateTime.day == now.day) {
            return true;
          }
        } catch (_) {}
      }
      return false;
    }

    // Combine notices from both NoticeStore and profile
    final List<dynamic> profileSliderNotices = AuthStore().profile?['slider_notices'] as List? ?? [];
    final Map<int, dynamic> uniqueNotices = {};
    for (var n in profileSliderNotices) {
      if (n is Map && shouldShowNotice(n)) {
        uniqueNotices[n['id'] as int] = n;
      }
    }
    for (var n in NoticeStore().notices) {
      if (n is Map && (n['show_in_slider'] == true || n['show_in_slider'] == 1) && shouldShowNotice(n)) {
        uniqueNotices[n['id'] as int] = n;
      }
    }
    final sliderNotices = uniqueNotices.values.toList();

    if (sliderNotices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOTICES'.tr,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: colors.secondaryText,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              _sliderDownPos = event.position;
              _sliderDownTime = DateTime.now();
            },
            onPointerUp: (event) {
              if (_sliderDownPos != null && _sliderDownTime != null) {
                final distance = (event.position - _sliderDownPos!).distance;
                final duration = DateTime.now().difference(_sliderDownTime!);
                if (distance < 12.0 && duration.inMilliseconds < 250) {
                  if (_currentNoticeIndex >= 0 && _currentNoticeIndex < sliderNotices.length) {
                    final notice = Map<String, dynamic>.from(sliderNotices[_currentNoticeIndex] as Map);
                    _handleNoticeTap(notice, notice['id'] as int? ?? 0);
                  }
                }
              }
            },
            child: PageView.builder(
              controller: PageController(),
              itemCount: sliderNotices.length,
              onPageChanged: (index) {
                setState(() {
                  _currentNoticeIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final notice = Map<String, dynamic>.from(sliderNotices[index] as Map);
                final title = notice['title'] ?? '';
                final description = notice['description'] ?? '';
                final id = notice['id'] as int? ?? 0;

                final List<Color> gradientColors = index % 3 == 0
                    ? [const Color(0xFF2563EB), const Color(0xFF8B5CF6)]
                    : index % 3 == 1
                        ? [const Color(0xFFEC4899), const Color(0xFFF59E0B)]
                        : [const Color(0xFF10B981), const Color(0xFF3B82F6)];

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleNoticeTap(notice, id),
                    borderRadius: BorderRadius.circular(20),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: colors.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.border,
                        ),
                        boxShadow: isDarkMode
                            ? []
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                )
                              ],
                      ),
                      child: Stack(
                        children: [
                          // Top-right background ambient glow circle
                          Positioned(
                            right: -24,
                            top: -24,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    gradientColors.first.withValues(alpha: 0.15),
                                    gradientColors.first.withValues(alpha: 0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Content layout
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Title Header Row with small campaign icon
                                Row(
                                  children: [
                                    Icon(
                                      Icons.campaign_rounded,
                                      size: 16,
                                      color: gradientColors.first,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: colors.primaryText,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Right chevron icon
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: colors.secondaryText,
                                      size: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // Description (takes up most of the space)
                                Expanded(
                                  child: Text(
                                    description,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.secondaryText,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // BS date capsule
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: colors.border,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 10,
                                        color: colors.secondaryText,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        (notice['start_date_bs']?.toString() ?? '').trd,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: colors.secondaryText,
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
                  ),
                ),
              );
            },
          ),
        ),
      ),
        if (sliderNotices.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(sliderNotices.length, (idx) {
              final isActive = idx == _currentNoticeIndex;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? colors.primaryText
                      : colors.border,
                ),
              );
            }),
          ),
        ],
        const SizedBox(height: 2),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, bool isDarkMode) {
    return ErrorStateView(
      errorMessage: widget.errorMessage,
      onRetry: widget.onRefresh,
      isDarkMode: isDarkMode,
    );
  }
}
