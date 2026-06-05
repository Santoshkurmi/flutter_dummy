import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../store/notification_store.dart';
import '../../services/translation_service.dart';

class NotificationsTab extends StatefulWidget {
  final bool isDarkMode;

  const NotificationsTab({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<NotificationsTab> with WidgetsBindingObserver {
  bool _isNotificationPermissionEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkNotificationPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkNotificationPermission();
    }
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _isNotificationPermissionEnabled = status.isGranted;
      });
    }
  }

  String _formatTime(String isoString) {
    try {
      final dateTime = DateTime.parse(isoString);
      final difference = DateTime.now().difference(dateTime);
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else {
        return '${dateTime.day} ${_getMonthName(dateTime.month)}';
      }
    } catch (_) {
      return '';
    }
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return '';
  }

  IconData _getIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('security') || t.contains('login') || t.contains('device')) {
      return Icons.security_rounded;
    } else if (t.contains('interest') || t.contains('accrued') || t.contains('rate')) {
      return Icons.account_balance_wallet_rounded;
    } else if (t.contains('loan') || t.contains('payment') || t.contains('repayment')) {
      return Icons.receipt_long_rounded;
    } else if (t.contains('board') || t.contains('notice') || t.contains('agm') || t.contains('meeting')) {
      return Icons.campaign_rounded;
    } else if (t.contains('deposit') || t.contains('received')) {
      return Icons.add_card_rounded;
    }
    return Icons.notifications_active_rounded;
  }

  Color _getIconColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('security') || t.contains('login') || t.contains('device')) {
      return const Color(0xFFF59E0B); // Amber
    } else if (t.contains('interest') || t.contains('accrued') || t.contains('rate')) {
      return const Color(0xFF2563EB); // Blue
    } else if (t.contains('loan') || t.contains('payment') || t.contains('repayment')) {
      return const Color(0xFFEF4444); // Red/Rose
    } else if (t.contains('board') || t.contains('notice') || t.contains('agm') || t.contains('meeting')) {
      return const Color(0xFF8B5CF6); // Purple
    } else if (t.contains('deposit') || t.contains('received')) {
      return const Color(0xFF10B981); // Emerald
    }
    return const Color(0xFF3B82F6); // Default Blue
  }

  Widget _buildPermissionAlertBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.3 : 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_off_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications Disabled'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Notification permission is disabled or denied. You will not receive transaction alerts, statement updates, or security announcements.'.tr,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => openAppSettings(),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.settings_rounded, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Enable in Settings'.tr,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateContent(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 16,
              ),
            ],
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            size: 64,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'No Notifications Yet'.tr,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'When you receive transactional alerts or cooperative news, they will appear here.'.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF64748B),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          AnimatedBuilder(
            animation: NotificationStore(),
            builder: (context, _) {
              final store = NotificationStore();
              if (store.notifications.isEmpty) return const SizedBox.shrink();

              final hasUnread = store.unreadCount > 0;

              return Row(
                children: [
                  if (hasUnread)
                    TextButton.icon(
                      icon: const Icon(Icons.mark_email_read_rounded, size: 16),
                      label: const Text('Read All', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        foregroundColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                      ),
                      onPressed: () => store.markAllAsRead(),
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete_sweep_rounded, size: 16),
                    label: const Text('Clear All', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                          title: Text('Clear Notifications', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B))),
                          content: Text('Are you sure you want to delete all notifications?', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel', style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                            ),
                            TextButton(
                              onPressed: () {
                                store.clearAll();
                                Navigator.pop(context);
                              },
                              child: const Text('Delete All', style: TextStyle(color: Color(0xFFEF4444))),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              );
            },
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: NotificationStore(),
        builder: (context, _) {
          final store = NotificationStore();
          final list = store.notifications;

          final hasBanner = !_isNotificationPermissionEnabled;
          final itemCount = list.length + (hasBanner ? 1 : 0);

          if (list.isEmpty) {
            if (hasBanner) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildPermissionAlertBanner(isDark),
                  const SizedBox(height: 40),
                  _buildEmptyStateContent(isDark),
                ],
              );
            }
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: _buildEmptyStateContent(isDark),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: itemCount,
            separatorBuilder: (context, index) {
              if (hasBanner && index == 0) {
                return const SizedBox(height: 16);
              }
              return const SizedBox(height: 12);
            },
            itemBuilder: (context, index) {
              if (hasBanner && index == 0) {
                return _buildPermissionAlertBanner(isDark);
              }
              final itemIndex = hasBanner ? index - 1 : index;
              final item = list[itemIndex];
              final icon = _getIcon(item['title']);
              final iconColor = _getIconColor(item['title']);
              final isRead = item['isRead'] == true;

              return Dismissible(
                key: Key(item['id']),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
                ),
                onDismissed: (direction) {
                  store.deleteNotification(item['id']);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${item['title']}" deleted'),
                      duration: const Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'Undo',
                        textColor: const Color(0xFF60A5FA),
                        onPressed: () {
                          store.addNotification(
                            title: item['title'],
                            body: item['body'],
                            timestamp: DateTime.tryParse(item['timestamp'] ?? ''),
                          );
                        },
                      ),
                    ),
                  );
                },
                child: InkWell(
                  onTap: () {
                    if (!isRead) {
                      store.markAsRead(item['id']);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? (isRead ? const Color(0xFF0F172A) : const Color(0xFF1E293B).withValues(alpha: 0.5))
                          : (isRead ? Colors.white : const Color(0xFFEFF6FF)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? (isRead ? Colors.white.withValues(alpha: 0.04) : const Color(0xFF3B82F6).withValues(alpha: 0.2))
                            : (isRead ? Colors.black.withValues(alpha: 0.04) : const Color(0xFF3B82F6).withValues(alpha: 0.15)),
                      ),
                      boxShadow: isRead
                          ? []
                          : [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.05 : 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dynamic icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: isDark ? 0.15 : 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: iconColor, size: 20),
                        ),
                        const SizedBox(width: 14),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item['title'] ?? 'Notice',
                                            style: TextStyle(
                                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                              fontSize: 14,
                                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                                            ),
                                          ),
                                        ),
                                        if (!isRead) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF3B82F6),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTime(item['timestamp'] ?? ''),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item['body'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? (isRead ? const Color(0xFF94A3B8) : const Color(0xFFCBD5E1))
                                      : (isRead ? const Color(0xFF475569) : const Color(0xFF1E293B)),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
