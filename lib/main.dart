import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'widgets/flying_hero_interactor.dart';
import 'store/auth_store.dart';
import 'pages/auth/onboarding_page.dart';
import 'pages/auth/status_check_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'package:refresh_rate/refresh_rate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'store/notification_store.dart';
import 'dart:convert';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();
  final notification = message.notification;
  if (notification != null) {
    final title = notification.title ?? 'Alert';
    final body = notification.body ?? '';
    
    final prefs = await SharedPreferences.getInstance();
    final listStr = prefs.getString('local_notifications') ?? '[]';
    List<dynamic> list = [];
    try {
      list = jsonDecode(listStr);
    } catch (_) {}
    
    final newItem = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    };
    
    list.insert(0, newItem);
    if (list.length > 50) {
      list = list.sublist(0, 50);
    }
    
    await prefs.setString('local_notifications', jsonEncode(list));
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize Firebase Services
    await Firebase.initializeApp();
    // Setup background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  
  try {
    // Unlocks peak rate (90Hz / 120Hz / 144Hz) on supported Android and iOS devices
     RefreshRate.enable();
  } catch (e) {
    debugPrint("Failed to set high refresh rate: $e");
  }

  // Initialize Notification Store
  final notificationStore = NotificationStore();
  await notificationStore.init();

  // Initialize Auth Store (persistences and initial loadings)
  final authStore = AuthStore();
  await authStore.init();

  runApp(const BrightBankApp());
}

class AxisAwareScrollPhysics extends ScrollPhysics {
  const AxisAwareScrollPhysics({
    required this.verticalPhysics,
    required this.horizontalPhysics,
    super.parent,
  });

  final ScrollPhysics verticalPhysics;
  final ScrollPhysics horizontalPhysics;

  @override
  AxisAwareScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return AxisAwareScrollPhysics(
      verticalPhysics: verticalPhysics,
      horizontalPhysics: horizontalPhysics,
      parent: buildParent(ancestor),
    );
  }

  ScrollPhysics _getPhysicsForAxis(Axis axis) {
    return axis == Axis.vertical ? verticalPhysics : horizontalPhysics;
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    return _getPhysicsForAxis(position.axis).applyPhysicsToUserOffset(position, offset);
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    return _getPhysicsForAxis(position.axis).applyBoundaryConditions(position, value);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    return _getPhysicsForAxis(position.axis).createBallisticSimulation(position, velocity);
  }
}

class BouncingScrollBehavior extends MaterialScrollBehavior {
  const BouncingScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return AxisAwareScrollPhysics(
      verticalPhysics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      horizontalPhysics: super.getScrollPhysics(context),
    );
  }
}

class BrightBankApp extends StatelessWidget {
  const BrightBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AuthStore(),
      builder: (context, _) {
        final isDark = AuthStore().isDarkMode;
        return MaterialApp(
          navigatorKey: AuthStore.navigatorKey,
          title: 'Bright Sahakari',
          debugShowCheckedModeBanner: false,
          scrollBehavior: const BouncingScrollBehavior(),
          theme: ThemeData(
            useMaterial3: true,
            brightness: isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
            appBarTheme: AppBarTheme(
              systemOverlayStyle: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
                statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
              ),
            ),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2563EB),
              brightness: isDark ? Brightness.dark : Brightness.light,
              surface: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
            ),
            fontFamily: 'Roboto',
          ),
          home: const InitialRouter(),
          builder: (context, child) {
            return Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (event) {
                FlyingHeroTracker.handlePointerDown(event.position);
              },
              onPointerUp: (event) {
                FlyingHeroTracker.handlePointerUp(event.position);
              },
              child: child!,
            );
          },
        );
      },
    );
  }
}

class InitialRouter extends StatefulWidget {
  const InitialRouter({super.key});

  @override
  State<InitialRouter> createState() => _InitialRouterState();
}

class _InitialRouterState extends State<InitialRouter> {
  @override
  void initState() {
    super.initState();
    // Listen to changes in the global state to allow fast reactive routing
    AuthStore().addListener(_onStateChange);
  }

  @override
  void dispose() {
    AuthStore().removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = AuthStore();

    // 1. If authenticated -> Go directly to the Banking Dashboard
    if (store.isAuthenticated) {
      return const DashboardPage();
    }

    // 2. If cooperative selected and device has been linked/registered -> Go to Login Page
    final registeredMobile = store.registeredMobile;
    if (registeredMobile != null && registeredMobile.isNotEmpty) {
      return LoginPage(mobileNumber: registeredMobile);
    }

    // 3. If cooperative selected but device not registered -> Go to Status Check page
    if (store.hasCooperative) {
      return const StatusCheckPage();
    }

    // 4. Fallback: Go to Onboarding Page
    return const OnboardingPage();
  }
}
