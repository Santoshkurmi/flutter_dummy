import 'package:flutter/material.dart';
import '../../services/translation_service.dart';
import '../../services/api_service.dart';
import 'notice_detail_page.dart';
import '../../store/notice_store.dart';

class NoticeTab extends StatefulWidget {
  final bool isDarkMode;

  const NoticeTab({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<NoticeTab> createState() => _NoticeTabState();
}

class _NoticeTabState extends State<NoticeTab> {
  final ScrollController _scrollController = ScrollController();
  
  List<dynamic> _notices = [];
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoading = false;
  bool _isLoadMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    NoticeStore().addListener(_onStoreChange);
    _fetchNotices(1);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    NoticeStore().removeListener(_onStoreChange);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onStoreChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && !_isLoadMore && _currentPage < _lastPage) {
        _fetchNotices(_currentPage + 1);
      }
    }
  }

  Future<void> _fetchNotices(int page, {bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _errorMessage = null;
      });
    } else {
      setState(() {
        if (page == 1) {
          _isLoading = true;
        } else {
          _isLoadMore = true;
        }
        _errorMessage = null;
      });
    }

    try {
      final response = await ApiService().getNotices(page: page, perPage: 20);
      final responseCode = response['response_code'];
      
      if (responseCode == 1 && response['data'] != null) {
        final listData = response['data']['list'];
        List<dynamic> newNotices = [];
        int lastPage = 1;
        int currentPage = page;

        if (listData is Map) {
          final dataList = listData['data'];
          if (dataList is List) {
            newNotices = dataList;
          }
          currentPage = listData['current_page'] ?? page;
          lastPage = listData['last_page'] ?? 1;
        } else if (listData is List) {
          newNotices = listData;
        }

        setState(() {
          if (page == 1) {
            _notices = newNotices;
            NoticeStore().setNotices(newNotices);
          } else {
            _notices.addAll(newNotices);
          }
          _currentPage = currentPage;
          _lastPage = lastPage;
          _isLoading = false;
          _isLoadMore = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load notices'.tr);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isLoadMore = false;
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    }
  }

  Future<void> _onRefresh() async {
    await _fetchNotices(1, isRefresh: true);
  }

  Color _getIconColor(int priority) {
    if (priority >= 2) {
      return const Color(0xFFEF4444); // Red/Rose for high priority
    } else if (priority == 1) {
      return const Color(0xFFF59E0B); // Amber for medium
    }
    return const Color(0xFF8B5CF6); // Purple for normal notice
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final cardBgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDark 
        ? Colors.white.withValues(alpha: 0.04) 
        : Colors.black.withValues(alpha: 0.04);
    final titleColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final descColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Notice'.tr,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: Navigator.canPop(context),
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
            animation: NoticeStore(),
            builder: (context, _) {
              final store = NoticeStore();
              if (store.notices.isEmpty) return const SizedBox.shrink();

              final hasUnread = store.unreadCount > 0;
              if (!hasUnread) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: TextButton.icon(
                  icon: const Icon(Icons.mark_email_read_rounded, size: 16),
                  label: Text('Read All'.tr, style: const TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                  ),
                  onPressed: () => store.markAllAsRead(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xFF2563EB),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        child: _buildBody(isDark, cardBgColor, borderColor, titleColor, descColor),
      ),
    );
  }

  Widget _buildBody(
    bool isDark,
    Color cardBgColor,
    Color borderColor,
    Color titleColor,
    Color descColor,
  ) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2563EB),
        ),
      );
    }

    if (_errorMessage != null && _notices.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFEF4444),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: descColor,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: Text('Try Again'.tr),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _fetchNotices(1),
              ),
            ],
          ),
        ),
      );
    }

    if (_notices.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.campaign_rounded,
                    size: 64,
                    color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Notices Yet'.tr,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Important announcements and official notice board updates will appear here.'.tr,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: descColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _notices.length + (_currentPage < _lastPage ? 1 : 0),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _notices.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
          );
        }

        final item = _notices[index];
        final String title = item['title'] ?? '';
        final String description = item['description'] ?? '';
        final int priority = item['priority'] ?? 0;
        final int id = item['id'] as int? ?? 0;
        final String dateBs = item['start_date_bs'] ?? '';
        final hasImage = item['image_path'] != null && item['image_path'].toString().isNotEmpty;
        final iconColor = _getIconColor(priority);
        final bool isRead = NoticeStore().isNoticeRead(id);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              NoticeStore().markAsRead(id);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoticeDetailPage(
                    notice: item,
                    isDarkMode: isDark,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? (isRead ? cardBgColor : const Color(0xFF1E293B).withValues(alpha: 0.5))
                    : (isRead ? cardBgColor : const Color(0xFFEFF6FF)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? (isRead ? borderColor : const Color(0xFF3B82F6).withValues(alpha: 0.2))
                      : (isRead ? borderColor : const Color(0xFF3B82F6).withValues(alpha: 0.15)),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.05 : 0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon / Thumbnail image representation
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: isDark ? 0.15 : 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: hasImage
                          ? Image.network(
                              item['image_path'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.campaign_rounded,
                                  color: iconColor,
                                  size: 20,
                                );
                              },
                            )
                          : Icon(
                              Icons.campaign_rounded,
                              color: iconColor,
                              size: 20,
                            ),
                    ),
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
                                      title,
                                      style: TextStyle(
                                        fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                        fontSize: 14,
                                        color: titleColor,
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
                            if (dateBs.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Text(
                                dateBs.trd,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Truncated summary description
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: descColor,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isRead) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(
                        Icons.check_circle_outline_rounded,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
                        size: 22,
                      ),
                      onPressed: () {
                        NoticeStore().markAsRead(id);
                      },
                      tooltip: 'Mark as read'.tr,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      splashRadius: 20,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
