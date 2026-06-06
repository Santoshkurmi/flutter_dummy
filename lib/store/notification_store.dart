import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/nepali_calendar_service.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import '../pages/services/nepali_calendar_page.dart';
import 'auth_store.dart';

class NotificationStore extends ChangeNotifier with WidgetsBindingObserver {
  static final NotificationStore _instance = NotificationStore._internal();
  factory NotificationStore() => _instance;
  NotificationStore._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      loadNotifications();
      if (AuthStore().showDateNotification) {
        updateDateNotification(true);
      }
    }
  }

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> get notifications => _notifications;

  int get unreadCount => _notifications.where((n) => n['isRead'] == false).length;

  bool _launchedFromNotification = false;
  bool get launchedFromNotification => _launchedFromNotification;

  void clearLaunchedFromNotification() {
    _launchedFromNotification = false;
    notifyListeners();
  }

  void _handleCalendarPayload() {
    if (AuthStore.navigatorKey.currentState != null) {
      AuthStore.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(settings: const RouteSettings(name: 'NepaliCalendarPage'), builder: (_) => const NepaliCalendarPage(isFromNotification: true)),
        (route) => false,
      );
    } else {
      _launchedFromNotification = true;
      notifyListeners();
    }
  }

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
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            if (response.payload == 'calendar') {
              _handleCalendarPayload();
            }
          },
        );

        final launchDetails = await _localNotificationsPlugin.getNotificationAppLaunchDetails();
        if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
          if (launchDetails.notificationResponse?.payload == 'calendar') {
            _launchedFromNotification = true;
            notifyListeners();
          }
        }

        const MethodChannel('app.channel.navigation').setMethodCallHandler((call) async {
          if (call.method == 'onPayloadReceived') {
            final payload = call.arguments as String?;
            if (payload == 'calendar') {
              _handleCalendarPayload();
            }
          }
        });

        if (Platform.isAndroid) {
          try {
            final String? nativePayload = await const MethodChannel('app.channel.navigation')
                .invokeMethod<String>('getLaunchPayload');
            if (nativePayload == 'calendar') {
              _launchedFromNotification = true;
              notifyListeners();
            }
          } catch (e) {
            debugPrint('Error getting native launch payload: $e');
          }
        }

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
              messageId: message.messageId,
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

        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          final notification = message.notification;
          if (notification != null) {
            addNotification(
              title: notification.title ?? 'Alert',
              body: notification.body ?? '',
              messageId: message.messageId,
            );
          }
        });

        FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
          if (message != null) {
            final notification = message.notification;
            if (notification != null) {
              addNotification(
                title: notification.title ?? 'Alert',
                body: notification.body ?? '',
                messageId: message.messageId,
              );
            }
          }
        });
      } catch (_) {}
    }
    
    if (AuthStore().showDateNotification) {
      updateDateNotification(true);
    }
  }

  Future<void> updateDateNotification(bool enabled) async {
    if (!enabled) {
      await _localNotificationsPlugin.cancel(id: 999);
      return;
    }

    try {
      final now = DateTime.now();
      final todayBs = NepaliCalendarService.adToBs(now);
      final yearBs = todayBs[0];
      final monthBs = todayBs[1];
      final dayBs = todayBs[2];

      final isNepali = AuthStore().notificationLanguage == 'ne';
      String title;
      if (isNepali) {
        final nepaliWeekdays = ['आइतबार', 'सोमबार', 'मंगलबार', 'बुधबार', 'बिहीबार', 'शुक्रबार', 'शनिबार'];
        final monthNp = NepaliCalendarService.nepaliMonthsDevanagari[monthBs - 1];
        final weekdayNp = nepaliWeekdays[now.weekday % 7];
        final dayNp = TranslationService.toNepaliNumbers(dayBs.toString());
        final yearNp = TranslationService.toNepaliNumbers(yearBs.toString());
        title = '$monthNp $dayNp, $yearNp ($weekdayNp)';
      } else {
        final weekdayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        final weekdayShort = weekdayNames[now.weekday % 7];
        final monthEn = NepaliCalendarService.nepaliMonths[monthBs - 1];
        title = '$monthEn $dayBs, $yearBs ($weekdayShort)';
      }

      String event = '';
      try {
        final cacheEntry = await ApiService.readFromCache('/holidays', {
          'year_bs': yearBs.toString(),
          'month_bs': monthBs.toString(),
        });
        if (cacheEntry != null && cacheEntry['data'] != null) {
          final dataMap = cacheEntry['data'] as Map<String, dynamic>;
          final calendar = dataMap['calendar'] as List?;
          if (calendar != null) {
            final todayEvent = calendar.firstWhere(
              (dayData) => dayData['day'] == dayBs,
              orElse: () => null,
            );
            if (todayEvent != null) {
              final String holName = todayEvent['holiday_name'] ?? '';
              final bool isHoliday = todayEvent['is_holiday'] as bool? ?? false;
              if (holName.isNotEmpty && holName.toLowerCase() != 'saturday') {
                event = holName;
              } else if (isHoliday && holName.toLowerCase() == 'saturday') {
                event = 'Weekly Holiday';
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error reading holidays cache for notification: $e');
      }

      if (event.isEmpty && now.weekday == DateTime.saturday) {
        event = 'Weekly Holiday';
      }

      String body;
      if (isNepali) {
        if (event.isNotEmpty) {
          final translatedEvent = TranslationService.translateToNepali(event);
          body = 'आजको पर्व/बिदा: $translatedEvent';
        } else {
          body = 'आज कुनै विशेष पर्व/बिदा छैन';
        }
      } else {
        if (event.isNotEmpty) {
          body = "Today's Event: $event";
        } else {
          body = 'No events scheduled today';
        }
      }

      final AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'date_notification_channel',
        isNepali ? 'नेपाली पात्रो मिति' : 'Nepali Date Notification',
        channelDescription: isNepali ? 'नेपाली पात्रोको मिति र पर्वहरू देखाउँछ' : 'Displays persistent current Nepali date and events',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showWhen: false,
        onlyAlertOnce: true,
        silent: true,
        icon: '@mipmap/ic_launcher',
      );

      final NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await _localNotificationsPlugin.show(
        id: 999,
        title: title,
        body: body,
        notificationDetails: platformChannelSpecifics,
        payload: 'calendar',
      );
    } catch (e) {
      debugPrint('Error showing persistent notification: $e');
    }
  }

  Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
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

  Future<void> addNotification({
    required String title,
    required String body,
    String? messageId,
    DateTime? timestamp,
  }) async {
    if (messageId != null && _notifications.any((n) => n['messageId'] == messageId)) {
      return;
    }

    final newItem = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'messageId': messageId,
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
