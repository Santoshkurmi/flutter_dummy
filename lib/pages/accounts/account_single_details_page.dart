import 'package:flutter/material.dart';
import '../../widgets/cooperative_account_card.dart';
import '../../services/translation_service.dart';
import '../../store/auth_store.dart';
import 'account_ledger_page.dart';
import 'rate_logs_page.dart';
import 'loan_schedules_page.dart';

class AccountSingleDetailsPage extends StatefulWidget {
  final Map<String, dynamic> account;
  final String accountType; // savings, loans, shares
  final String? heroTag;
  final List<Map<String, dynamic>>? swipableAccounts;
  final int? initialIndex;

  const AccountSingleDetailsPage({
    super.key,
    required this.account,
    required this.accountType,
    this.heroTag,
    this.swipableAccounts,
    this.initialIndex,
  });

  @override
  State<AccountSingleDetailsPage> createState() => _AccountSingleDetailsPageState();
}

class _AccountSingleDetailsPageState extends State<AccountSingleDetailsPage> with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late List<Map<String, dynamic>> _accountsList;

  // Custom swipe logic state (matching HomeTab)
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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
    _accountsList = widget.swipableAccounts ?? [
      {'raw': widget.account, 'type': widget.accountType}
    ];

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
              int total = _accountsList.length;
              _currentIndex = (_currentIndex + _dismissDirection) % total;
              if (_currentIndex < 0) {
                _currentIndex += total;
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
    super.dispose();
  }

  void _animateDismiss(int direction) {
    double screenWidth = MediaQuery.of(context).size.width;
    double pageWidth = screenWidth - 40.0;
    
    _isDismissal = true;
    _dismissDirection = direction;
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
      int total = _accountsList.length;
      _currentIndex = (_currentIndex + _dismissDirection) % total;
      if (_currentIndex < 0) {
        _currentIndex += total;
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
    return _currentIndex - progress;
  }

  void _handleQuickAction(String title) {
    showDialog(
      context: context,
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text('The $title features are running in simulation modes for this demonstration account.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  void _showNotImplementedSnackBar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature feature is not implemented yet.'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E293B) 
            : const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Resolve active account details based on current index
    final activeItem = _accountsList[_currentIndex];
    final acc = activeItem['raw'];
    final accountType = activeItem['type'];
    
    final name = acc['name'] ?? 'Account';
    final isSavings = accountType == 'savings';
    final isLoan = accountType == 'loans';
    final isShare = accountType == 'shares';

    Color accentColor = const Color(0xFF2563EB); // savings blue
    if (accountType == 'loans') {
      accentColor = const Color(0xFFEF4444);
    } else if (accountType == 'shares') {
      accentColor = const Color(0xFF10B981);
    }

    IconData getIconForLabel(String label) {
      switch (label) {
        case 'Interest Rate':
          return Icons.percent_rounded;
        case 'Loan Amount':
          return Icons.monetization_on_rounded;
        case 'Loan Balance':
          return Icons.account_balance_rounded;
        case 'Accrued Interest':
        case 'Accrued Interest Due':
        case 'Due Interest':
        case 'Total Matured to Pay':
          return Icons.payments_rounded;
        case 'Minimum Balance':
          return Icons.wallet_rounded;
        case 'Opened Date (BS)':
          return Icons.calendar_today_rounded;
        case 'Maturity Date':
        case 'Maturity Date (BS)':
          return Icons.event_busy_rounded;
        case 'Interest Posting Date':
          return Icons.event_repeat_rounded;
        case 'Principal Fine':
        case 'Interest Fine':
        case 'Fine Amount':
          return Icons.gavel_rounded;
        case 'Matured Principal':
        case 'Principal Matured':
          return Icons.account_balance_rounded;
        case 'Share Capital Value':
          return Icons.monetization_on_rounded;
        case 'Total Share Units':
          return Icons.grid_view_rounded;
        case 'Member Status':
          return Icons.verified_user_rounded;
        default:
          return Icons.info_outline_rounded;
      }
    }

    // Build actions list dynamically based on account type
    final actions = <Map<String, dynamic>>[];

    if (!isLoan) {
      actions.add({
        'label': 'Deposit'.tr,
        'icon': Icons.add_circle_outline_rounded,
        'onTap': () => _showNotImplementedSnackBar('Deposit'),
      });
    }

    if (!isShare) {
      actions.add({
        'label': 'Payment'.tr,
        'icon': Icons.send_rounded,
        'onTap': () => _showNotImplementedSnackBar('Payment'),
      });
    }

    final accountNoForStatement = acc['accNo'] ?? acc['account_no'] ?? 'N/A';
    final String effectiveTagForStatement = widget.heroTag ?? 'ledger_$accountNoForStatement';

    actions.add({
      'label': 'Statement'.tr,
      'icon': Icons.download_rounded,
      'onTap': () {
        if (AccountLedgerPage.isOpening) return;
        AccountLedgerPage.isOpening = true;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AccountLedgerPage(
              account: acc,
              accountType: accountType,
              heroTag: effectiveTagForStatement,
              swipableAccounts: widget.swipableAccounts,
              initialIndex: _currentIndex,
            ),
          ),
        ).then((_) {
          AccountLedgerPage.isOpening = false;
          if (mounted) {
            setState(() {});
          }
        });
      },
    });

    if (isSavings || isLoan) {
      actions.add({
        'label': 'Rate Logs'.tr,
        'icon': Icons.history_rounded,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RateLogsPage(
                account: acc,
                accountType: accountType,
              ),
            ),
          );
        },
      });
    }

    if (isLoan) {
      actions.add({
        'label': 'Schedules'.tr,
        'icon': Icons.calendar_month_rounded,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LoanSchedulesPage(
                account: acc,
              ),
            ),
          );
        },
      });
    }

    // Build details list dynamically based on account type
    final List<Map<String, String>> detailsList = [];
    if (isSavings) {
      final String maturityDate = acc['maturity_date']?.toString() ?? 'N/A';
      final String rawPosting = acc['interest_credit_period']?.toString() ?? 'Quarterly';
      final String interestPosting = rawPosting.isNotEmpty
          ? '${rawPosting[0].toUpperCase()}${rawPosting.substring(1)} Capitalization'
          : 'Quarterly Capitalization';

      detailsList.addAll([
        {'label': 'Interest Rate'.tr, 'value': '${acc['interest_rate'] ?? '8.5'}% p.a.'},
        {'label': 'Accrued Interest'.tr, 'value': 'Rs. ${_formatAmount(acc['accrued_interest'])}'},
        {'label': 'Minimum Balance'.tr, 'value': 'Rs. ${_formatAmount(acc['min_balance'])}'},
        {'label': 'Opened Date (BS)'.tr, 'value': acc['issued_date']?.toString() ?? '2081-02-15'},
        {'label': 'Maturity Date'.tr, 'value': maturityDate},
        {'label': 'Interest Posting Date'.tr, 'value': interestPosting},
      ]);
    } else if (isLoan) {
      detailsList.addAll([
        {'label': 'Interest Rate'.tr, 'value': '${acc['interest_rate'] ?? '12.0'}% p.a.'},
        {'label': 'Loan Amount'.tr, 'value': 'Rs. ${_formatAmount(acc['loan_amount'])}'},
        {'label': 'Loan Balance'.tr, 'value': 'Rs. ${_formatAmount(acc['balance'])}'},
        {'label': 'Opened Date (BS)'.tr, 'value': acc['issued_date']?.toString() ?? '2080-11-10'},
        {'label': 'Maturity Date (BS)'.tr, 'value': acc['maturity_date']?.toString() ?? 'N/A'},
        {'label': 'Principal Matured'.tr, 'value': 'Rs. ${_formatAmount(acc['matured_principal'])}'},
        {'label': 'Accrued Interest'.tr, 'value': 'Rs. ${_formatAmount(acc['accrued_interest'])}'},
        {'label': 'Due Interest'.tr, 'value': 'Rs. ${_formatAmount(acc['due_interest'])}'},
        {'label': 'Fine Amount'.tr, 'value': 'Rs. ${_formatAmount(acc['fine_amount'])}'},
        {'label': 'Total Matured to Pay'.tr, 'value': 'Rs. ${_formatAmount(acc['total_matured_pay'])}'},
      ]);
    } else { // shares
      detailsList.addAll([
        {'label': 'Share Capital Value'.tr, 'value': 'Rs. ${_formatAmount(acc['balance'])}'},
        {'label': 'Total Share Units'.tr, 'value': '${acc['share_count'] ?? '100'} ${'Units'.tr}'},
        {'label': 'Opened Date (BS)'.tr, 'value': acc['issued_date']?.toString() ?? '2079-05-18'},
        {'label': 'Member Status'.tr, 'value': 'Active Shareholder'.tr},
      ]);
    }

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF020617) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context) ? IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ) : null,
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(left: 20.0, right: 20.0, top: 8.0, bottom: 20.0),
          physics: _isDraggingCard ? const NeverScrollableScrollPhysics() : null,
          children: [
            // Card swipe deck
            SizedBox(
              height: 190,
              child: ClipRRect(
                clipBehavior: Clip.none,
                child: _accountsList.length <= 1
                    ? _buildCardItem(context, _accountsList.first, isTopCard: true)
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          double pageWidth = constraints.maxWidth;
                          
                          int nextPageIndex = _dragOffset < 0
                              ? (_currentIndex + 1) % _accountsList.length
                              : (_currentIndex - 1 + _accountsList.length) % _accountsList.length;

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
                                  // Bottom Card
                                  Positioned.fill(
                                    child: Transform(
                                      transform: bottomMatrix,
                                      alignment: Alignment.center,
                                      child: IgnorePointer(
                                        child: _buildCardItem(context, _accountsList[nextPageIndex]),
                                      ),
                                    ),
                                  ),
                                  // Top Card
                                  Positioned.fill(
                                    child: Transform(
                                      transform: topMatrix,
                                      alignment: Alignment.center,
                                      child: _buildCardItem(context, _accountsList[_currentIndex], isTopCard: true),
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
            if (_accountsList.length > 1) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_accountsList.length, (index) {
                  double page = _currentPage % _accountsList.length;
                  if (page < 0) {
                    page += _accountsList.length;
                  }
                  double diff = index - page;
                  if (diff > _accountsList.length / 2.0) {
                    diff -= _accountsList.length;
                  } else if (diff < -_accountsList.length / 2.0) {
                    diff += _accountsList.length;
                  }
                  double distance = diff.abs();
                  double activeRatio = (1.0 - distance.clamp(0.0, 1.0));
                  double width = 6.0 + (14.0 * activeRatio);

                  final card = _accountsList[index];
                  final type = card['type'] as String?;
                  Color cardAccentColor;
                  if (type == 'savings') {
                    cardAccentColor = const Color(0xFF6366F1);
                  } else if (type == 'shares') {
                    cardAccentColor = const Color(0xFF10B981);
                  } else if (type == 'loans') {
                    cardAccentColor = const Color(0xFFF43F5E);
                  } else {
                    cardAccentColor = const Color(0xFF2563EB);
                  }

                  final inactiveColor = isDarkMode
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

            // AnimatedSwitcher for smooth switching of actions and details
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Column(
                key: ValueKey<int>(_currentIndex),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Quick Actions Grid
                  Text(
                    'Quick Actions'.toUpperCase().tr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.9,
                    children: actions.map((act) {
                      return _buildActionGridButton(
                        act['label'] as String,
                        act['icon'] as IconData,
                        isDarkMode,
                        onTap: act['onTap'] as VoidCallback,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // Detailed Card
                  Text(
                    'Account Information'.toUpperCase().tr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: isDarkMode ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.02),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      children: List.generate(detailsList.length, (index) {
                        final detail = detailsList[index];
                        final isLast = index == detailsList.length - 1;
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: isDarkMode ? 0.15 : 0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      getIconForLabel(detail['label']!),
                                      color: isDarkMode ? accentColor.withValues(alpha: 0.8) : accentColor,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      detail['label']!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDarkMode ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Flexible(
                                    child: Text(
                                      detail['value']!,
                                      textAlign: TextAlign.end,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isLast)
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFEFF6FF),
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCardItem(BuildContext context, Map<String, dynamic> cardData, {bool isTopCard = false}) {
    final acc = cardData['raw'];
    final type = cardData['type'];
    final double rawBalance = (acc['balance'] ?? 0.0).toDouble();
    final balance = 'Rs. ${_formatAmount(rawBalance)}';
    final accountNo = acc['accNo'] ?? acc['account_no'] ?? 'N/A';
    final title = acc['name'] ?? 'Account';

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final String? effectiveTag = isTopCard ? (widget.heroTag ?? 'ledger_$accountNo') : null;

    return CooperativeAccountCard(
      isOverview: false,
      accountType: type,
      title: title,
      balance: balance,
      accountNo: accountNo,
      interestRate: acc['interest_rate'],
      shareCount: acc['share_count'],
      maturityDate: acc['maturity_date'],
      showBalance: true,
      isDarkMode: isDarkMode,
      showArrow: true,
      heroTag: effectiveTag,
      onTap: () {
        if (AccountLedgerPage.isOpening) return;
        AccountLedgerPage.isOpening = true;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AccountLedgerPage(
              account: acc,
              accountType: type,
              heroTag: effectiveTag,
              swipableAccounts: widget.swipableAccounts,
              initialIndex: _currentIndex,
            ),
          ),
        ).then((_) {
          AccountLedgerPage.isOpening = false;
          if (mounted) {
            setState(() {});
          }
        });
      },
    );
  }

  Widget _buildActionGridButton(String label, IconData icon, bool isDarkMode, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFDBEAFE),
              ),
            ),
            child: Icon(
              icon,
              color: isDarkMode ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
