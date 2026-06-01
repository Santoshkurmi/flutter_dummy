import 'package:flutter/material.dart';
import '../services/translation_service.dart';
import 'flying_hero_interactor.dart';

class CooperativeAccountCard extends StatelessWidget {
  final bool isOverview;
  final String accountType; // "savings", "shares", "loans", "overview"
  final String title;
  final String balance;
  final String accountNo;
  final dynamic interestRate;
  final dynamic shareCount;
  final dynamic maturityDate;
  final String? loanBalance;
  final String? shareBalance;
  final bool showBalance;
  final bool isDarkMode;
  final bool showArrow;
  final VoidCallback? onTap;
  final String? heroTag;

  const CooperativeAccountCard({
    super.key,
    required this.isOverview,
    required this.accountType,
    required this.title,
    required this.balance,
    required this.accountNo,
    this.interestRate,
    this.shareCount,
    this.maturityDate,
    this.loanBalance,
    this.shareBalance,
    required this.showBalance,
    required this.isDarkMode,
    this.showArrow = true,
    this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    // Gradients
    LinearGradient gradient;
    if (isOverview) {
      gradient = isDarkMode
          ? const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF4C1D95)], begin: Alignment.topLeft, end: Alignment.bottomRight)
          : const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)], begin: Alignment.topLeft, end: Alignment.bottomRight);
    } else {
      switch (accountType) {
        case 'savings':
          gradient = isDarkMode
              ? const LinearGradient(colors: [Color(0xFF312E81), Color(0xFF701A75)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFD946EF)], begin: Alignment.topLeft, end: Alignment.bottomRight);
          break;
        case 'shares':
          gradient = isDarkMode
              ? const LinearGradient(colors: [Color(0xFF115E59), Color(0xFF065F46)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF10B981)], begin: Alignment.topLeft, end: Alignment.bottomRight);
          break;
        case 'loans':
          gradient = isDarkMode
              ? const LinearGradient(colors: [Color(0xFF9F1239), Color(0xFF7C2D12)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : const LinearGradient(colors: [Color(0xFFF43F5E), Color(0xFFFB923C)], begin: Alignment.topLeft, end: Alignment.bottomRight);
          break;
        default:
          gradient = isDarkMode
              ? const LinearGradient(colors: [Color(0xFF1E3A8A), Color(0xFF4C1D95)], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF7C3AED)], begin: Alignment.topLeft, end: Alignment.bottomRight);
      }
    }

    // Icon selection
    IconData headerIcon;
    Color iconColor;
    if (isOverview) {
      headerIcon = Icons.stars_rounded;
      iconColor = const Color(0xFFFCD34D); // Bright Amber/Gold
    } else {
      switch (accountType) {
        case 'savings':
          headerIcon = Icons.account_balance_wallet_rounded;
          iconColor = const Color(0xFFA5B4FC); // Soft Light Indigo
          break;
        case 'shares':
          headerIcon = Icons.pie_chart_rounded;
          iconColor = const Color(0xFF6EE7B7); // Soft Mint/Green
          break;
        case 'loans':
          headerIcon = Icons.business_center_rounded;
          iconColor = const Color(0xFFFCD34D); // Bright Amber/Yellow
          break;
        default:
          headerIcon = Icons.stars_rounded;
          iconColor = const Color(0xFFFCD34D);
      }
    }

    final cardWidget = GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background Container with Gradient & Border
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.white.withValues(alpha: 0.15),
                  ),
                ),
              ),
            ),
            // Decorative Overlay Circle 1 (Large, bottom-right)
            Positioned(
              right: -40,
              bottom: -40,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            // Decorative Overlay Circle 2 (Medium, bottom-right/mid)
            Positioned(
              right: 20,
              bottom: -70,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.03),
                ),
              ),
            ),
            // Content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                                child: Icon(
                                  headerIcon,
                                  color: iconColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showArrow)
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: onTap,
                          )
                        else
                          Opacity(
                            opacity: 0.0,
                            child: IgnorePointer(
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                onPressed: null,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    // Balance Column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOverview ? 'TOTAL ACCOUNT BALANCE'.tr : 'AVAILABLE BALANCE'.tr,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withValues(alpha: 0.65),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          showBalance ? balance : '••••••••',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    
                    // Divider
                    Container(
                      height: 1,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    
                    // Bottom row
                  isOverview
                      ? Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.business_center_rounded,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'LOAN BALANCE'.tr,
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white.withValues(alpha: 0.7),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          showBalance ? (loanBalance ?? 'Rs. 0.00') : '••••',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          'SHARE CAPITAL'.tr,
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white.withValues(alpha: 0.7),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          showBalance ? (shareBalance ?? 'Rs. 0.00') : '••••',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.pie_chart_rounded,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.info_outline_rounded,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ACCOUNT NO.'.tr,
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white.withValues(alpha: 0.7),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          accountNo,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontFamily: 'monospace',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          (accountType == 'savings' || accountType == 'loans'
                                                  ? 'INTEREST RATE'
                                                  : 'NO. OF SHARES')
                                              .tr,
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white.withValues(alpha: 0.7),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          accountType == 'savings' || accountType == 'loans'
                                              ? '${interestRate ?? 0}%'
                                              : '${shareCount ?? 0}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      accountType == 'savings' || accountType == 'loans'
                                          ? Icons.trending_up_rounded
                                          : Icons.pie_chart_outline_rounded,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );

  if (heroTag != null) {
    return Hero(
      tag: heroTag!,
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        final Widget shuttle;
        if (toHeroContext.widget is Hero) {
          shuttle = (toHeroContext.widget as Hero).child;
        } else if (fromHeroContext.widget is Hero) {
          shuttle = (fromHeroContext.widget as Hero).child;
        } else {
          shuttle = cardWidget;
        }

        final onTap = _findOnTapInWidget(toHeroContext.widget) ?? _findOnTapInWidget(fromHeroContext.widget);

        if (onTap != null) {
          return FlyingShuttleWrapper(
            onTap: onTap,
            pageContext: toHeroContext,
            child: shuttle,
          );
        }

        return shuttle;
      },
      child: Material(
        type: MaterialType.transparency,
        child: cardWidget,
      ),
    );
  }
  return cardWidget;
}
}

VoidCallback? _findOnTapInWidget(Widget? widget) {
  if (widget == null) return null;
  if (widget is GestureDetector) {
    return widget.onTap;
  }
  if (widget is InkWell) {
    return widget.onTap;
  }
  if (widget is Hero) {
    return _findOnTapInWidget(widget.child);
  }
  if (widget is Material) {
    return _findOnTapInWidget(widget.child);
  }
  if (widget is AnimatedBuilder) {
    return _findOnTapInWidget(widget.child);
  }
  return null;
}

