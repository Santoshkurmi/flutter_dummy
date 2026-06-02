import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationStore extends ChangeNotifier {
  static final NotificationStore _instance = NotificationStore._internal();
  factory NotificationStore() => _instance;
  NotificationStore._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => n['isRead'] == false).length;

  Future<void> init() async {
    await loadNotifications();
    
    // Listen to foreground FCM messages
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        const DarwinInitializationSettings initializationSettingsDarwin =
            DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

        const InitializationSettings initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

        await _localNotificationsPlugin.initialize(
          settings: initializationSettings,
        );

        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel',
          'General Notification',
          description: 'This is for saving,loan,share etc transaction notification of member',
          importance: Importance.max,
        );

        await _localNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);

        await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          if (notification != null) {
            addNotification(
              title: notification.title ?? 'Alert',
              body: notification.body ?? '',
            );

            if (Platform.isAndroid) {
              _localNotificationsPlugin.show(
                id: notification.hashCode,
                title: notification.title,
                body: notification.body,
                notificationDetails: NotificationDetails(
                  android: AndroidNotificationDetails(
                    channel.id,
                    channel.name,
                    channelDescription: channel.description,
                    importance: Importance.max,
                    priority: Priority.high,
                    icon: '@mipmap/ic_launcher',
                  ),
                ),
              );
            }
          }
        });
      } catch (_) {}
    }
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
      _notifications = [];
    }
    notifyListeners();
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
