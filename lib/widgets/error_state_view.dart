import 'package:flutter/material.dart';
import '../services/translation_service.dart';

class ErrorStateView extends StatefulWidget {
  final String? errorMessage;
  final Future<void> Function() onRetry;
  final bool isDarkMode;

  const ErrorStateView({
    super.key,
    this.errorMessage,
    required this.onRetry,
    required this.isDarkMode,
  });

  @override
  State<ErrorStateView> createState() => _ErrorStateViewState();
}

class _ErrorStateViewState extends State<ErrorStateView> with TickerProviderStateMixin {
  bool _isRetrying = false;
  late AnimationController _pulseController;
  late AnimationController _rotateController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  void _handleRetry() async {
    if (_isRetrying) return;
    setState(() {
      _isRetrying = true;
    });
    _rotateController.repeat();

    try {
      await widget.onRetry();
    } catch (_) {
      // Errors should be handled by the parent
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
        _rotateController.stop();
      }
    }
  }

  IconData _getErrorIcon(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return Icons.timer_off_rounded;
    } else if (lower.contains('internet') || lower.contains('unreachable') || lower.contains('socket')) {
      return Icons.wifi_off_rounded;
    } else if (lower.contains('invalid response') || lower.contains('format')) {
      return Icons.dns_rounded;
    } else if (lower.contains('secure') || lower.contains('handshake') || lower.contains('ssl')) {
      return Icons.gpp_bad_rounded;
    }
    return Icons.error_outline_rounded;
  }

  String _getErrorTitle(String msg) {
    final lower = msg.toLowerCase();
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return 'Connection Timeout'.tr;
    } else if (lower.contains('internet') || lower.contains('unreachable') || lower.contains('socket')) {
      return 'Connection Failed'.tr;
    } else if (lower.contains('invalid response')) {
      return 'Invalid Response'.tr;
    } else if (lower.contains('secure') || lower.contains('handshake') || lower.contains('ssl')) {
      return 'Security Error'.tr;
    }
    return 'Something Went Wrong'.tr;
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.errorMessage ?? 'No internet connection or server is unreachable.'.tr;
    final icon = _getErrorIcon(msg);
    final title = _getErrorTitle(msg);
    
    final Color ringColor = widget.isDarkMode 
        ? const Color(0xFFEF4444).withValues(alpha: 0.15) 
        : const Color(0xFFFEE2E2);
    final Color iconColor = widget.isDarkMode 
        ? const Color(0xFFF87171) 
        : const Color(0xFFEF4444);
    final Color titleColor = widget.isDarkMode 
        ? Colors.white 
        : const Color(0xFF1E293B);
    final Color subtitleColor = widget.isDarkMode 
        ? const Color(0xFF94A3B8) 
        : const Color(0xFF64748B);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 60),
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
                  colors: widget.isDarkMode 
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
                  _PulseRing(controller: _pulseController, factor: 0.8, ringColor: ringColor),
                  _PulseRing(controller: _pulseController, factor: 1.2, ringColor: ringColor),
                  Icon(
                    icon,
                    size: 60,
                    color: iconColor,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: subtitleColor,
              ),
            ),
          ),
          const SizedBox(height: 36),
          ElevatedButton(
            onPressed: _isRetrying ? null : _handleRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.6),
              disabledForegroundColor: Colors.white.withValues(alpha: 0.8),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: _isRetrying ? 1 : 4,
              shadowColor: const Color(0xFFEF4444).withValues(alpha: 0.4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RotationTransition(
                  turns: _rotateController,
                  child: const Icon(Icons.refresh_rounded, size: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  _isRetrying ? 'Refreshing...'.tr : 'Try Again'.tr,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  final AnimationController controller;
  final double factor;
  final Color ringColor;

  const _PulseRing({
    required this.controller,
    required this.factor,
    required this.ringColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final val = (controller.value + (factor - 1.0)) % 1.0;
        return Container(
          width: 140 * (0.8 + 0.4 * val),
          height: 140 * (0.8 + 0.4 * val),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: ringColor.withValues(alpha: (1.0 - val) * 0.4),
              width: 2.0,
            ),
          ),
        );
      },
    );
  }
}
