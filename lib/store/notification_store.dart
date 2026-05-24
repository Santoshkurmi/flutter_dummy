import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationStore extends ChangeNotifier {
  static final NotificationStore _instance = NotificationStore._internal();
  factory NotificationStore() => _instance;
  NotificationStore._internal();

  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => n['isRead'] == false).length;

  Future<void> init() async {
    await loadNotifications();
    
    // Listen to foreground FCM messages
    try {
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final notification = message.notification;
        if (notification != null) {
          addNotification(
            title: notification.title ?? 'Alert',
            body: notification.body ?? '',
          );
        }
      });
    } catch (_) {}
  }

  Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final listStr = prefs.getString('local_notifications');
    
    if (listStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(listStr);
        _notifications = decoded.map((item) => Map<String, dynamic>.from(item)).toList();
      } catch (_) {
        _notifications = [];
      }
    } else {
      // If no notifications exist, populate dummy ones
      _notifications = _getDummyNotifications();
      await saveNotifications();
    }
    notifyListeners();
  }

  List<Map<String, dynamic>> _getDummyNotifications() {
    final now = DateTime.now();
    return [
      {
        'id': 'dummy-1',
        'title': 'Cooperative Board Update',
        'body': 'Notice: The Annual General Meeting (AGM) has been scheduled for next Saturday at 11:00 AM. Please make sure to attend.',
        'timestamp': now.subtract(const Duration(hours: 2)).toIso8601String(),
        'isRead': false,
      },
      {
        'id': 'dummy-2',
        'title': 'Interest Accrued Alert',
        'body': 'Your savings account Acc. *4839 has been credited with Rs. 1,450.00 interest for the fourth quarter.',
        'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
        'isRead': true,
      },
      {
        'id': 'dummy-3',
        'title': 'Security Login Alert',
        'body': 'Successful login detected on a new Android device (Samsung S21) at 10:45 AM. If this wasn\'t you, please secure your account.',
        'timestamp': now.subtract(const Duration(days: 2)).toIso8601String(),
        'isRead': true,
      },
      {
        'id': 'dummy-4',
        'title': 'Loan Repayment Success',
        'body': 'Payment of Rs. 15,000.00 received towards Loan Account *2930. Thank you for your timely payment.',
        'timestamp': now.subtract(const Duration(days: 3)).toIso8601String(),
        'isRead': true,
      },
    ];
  }

  Future<void> saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('local_notifications', jsonEncode(_notifications));
  }

  Future<void> addNotification({required String title, required String body, DateTime? timestamp}) async {
    final newItem = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'timestamp': (timestamp ?? DateTime.now()).toIso8601String(),
      'isRead': false,
    };
    
    _notifications.insert(0, newItem);
    
    // Limit to 50
    if (_notifications.length > 50) {
      _notifications = _notifications.sublist(0, 50);
    }
    
    await saveNotifications();
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n['id'] == id);
    if (index != -1) {
      _notifications[index]['isRead'] = true;
      await saveNotifications();
      notifyListeners();
    }
  }

  Future<void> markAllAsRead() async {
    for (var n in _notifications) {
      n['isRead'] = true;
    }
    await saveNotifications();
    notifyListeners();
  }

  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n['id'] == id);
    await saveNotifications();
    notifyListeners();
  }

  Future<void> clearAll() async {
    _notifications.clear();
    await saveNotifications();
    notifyListeners();
  }
}
