import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NoticeStore extends ChangeNotifier {
  static final NoticeStore _instance = NoticeStore._internal();
  factory NoticeStore() => _instance;
  NoticeStore._internal();

  List<dynamic> _notices = [];
  Set<int> _readNoticeIds = {};

  List<dynamic> get notices => _notices;
  Set<int> get readNoticeIds => _readNoticeIds;

  // Calculates the count of unread notices (ID not in _readNoticeIds)
  int get unreadCount {
    if (_notices.isEmpty) return 0;
    return _notices.where((notice) {
      final id = notice['id'] as int? ?? 0;
      return id > 0 && !_readNoticeIds.contains(id);
    }).length;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final readIdsList = prefs.getStringList('read_notice_ids') ?? [];
    _readNoticeIds = readIdsList.map((s) => int.tryParse(s) ?? 0).toSet();
    _readNoticeIds.remove(0); // Clean up any invalid parses
    notifyListeners();
  }

  // Updates the list of notices from API fetches
  void setNotices(List<dynamic> list) {
    _notices = list;
    notifyListeners();
  }

  // Marks a specific notice as read
  Future<void> markAsRead(int id) async {
    if (id <= 0) return;
    if (!_readNoticeIds.contains(id)) {
      _readNoticeIds.add(id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'read_notice_ids',
        _readNoticeIds.map((id) => id.toString()).toList(),
      );
      notifyListeners();
    }
  }

  // Marks all fetched notices as read
  Future<void> markAllAsRead() async {
    if (_notices.isEmpty) return;
    
    bool changed = false;
    for (var notice in _notices) {
      final id = notice['id'] as int? ?? 0;
      if (id > 0 && !_readNoticeIds.contains(id)) {
        _readNoticeIds.add(id);
        changed = true;
      }
    }

    if (changed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        'read_notice_ids',
        _readNoticeIds.map((id) => id.toString()).toList(),
      );
      notifyListeners();
    }
  }

  // Checks if a notice is read
  bool isNoticeRead(int id) {
    return _readNoticeIds.contains(id);
  }
}
