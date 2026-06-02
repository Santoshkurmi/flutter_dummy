import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'widgets/flying_hero_interactor.dart';
import 'store/auth_store.dart';
import 'pages/auth/onboarding_page.dart';
import 'pages/auth/status_check_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/settings/biometric_setup_page.dart';
// import 'package:refresh_rate/refresh_rate.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'store/notification_store.dart';
import 'services/location_service.dart';
import 'services/api_service.dart';
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

  // Load environment variables from .env
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Failed to load .env file: $e");
  }
  
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      // Initialize Firebase Services
      await Firebase.initializeApp();
      // Setup background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint("Firebase initialization failed: $e");
    }
  }
  
  try {
    // Unlocks peak rate (90Hz / 120Hz / 144Hz) on supported Android and iOS devices
    //  RefreshRate.enable();
  } catch (e) {
    debugPrint("Failed to set high refresh rate: $e");
  }

  // Initialize Notification Store
  final notificationStore = NotificationStore();
  await notificationStore.init();

  // Initialize Auth Store (persistences and initial loadings)
  final authStore = AuthStore();
  await authStore.init();

  // Clear API cache periodically on startup (every 2 hours)
  await ApiService.checkAndClearCacheOnAppStart();

  // Initialize Location Service
  final locationService = LocationService();
  await locationService.init();

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
          title: AuthStore().isCustomApp
              ? (AuthStore().selectedCooperative?['name'] ?? 'Mbright')
              : 'Mbright',
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
            final MediaQueryData data = MediaQuery.of(context);
            return MediaQuery(
              data: data.copyWith(
                textScaler: data.textScaler.clamp(
                  minScaleFactor: 0.85,
                  maxScaleFactor: 1.06,
                ),
              ),
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  FlyingHeroTracker.handlePointerDown(event.position);
                },
                onPointerUp: (event) {
                  FlyingHeroTracker.handlePointerUp(event.position);
                },
                child: child!,
              ),
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

    // Schedule background location fetch when the app is idle after startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SchedulerBinding.instance.scheduleTask(
        () async {
          await LocationService().refreshLocationOnStartup();
        },
        Priority.idle,
      );
    });
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

    // 1. If authenticated → check if biometric setup is pending first
    if (store.isAuthenticated) {
      if (store.pendingBiometricSetup) {
        return const BiometricSetupPage();
      }
      return const DashboardPage();
    }

    // 2. If cooperative selected and device has been linked/registered -> Go to Login Page
    final registeredMobile = store.registeredMobile;
    if (registeredMobile != null && registeredMobile.isNotEmpty) {
      return LoginPage(mobileNumber: registeredMobile);
    }

    // 3. For Custom App: if preferences setup is completed, we bypass Select Cooperative and go to StatusCheckPage
    if (store.isCustomApp) {
      if (store.preferencesSetupCompleted) {
        return const StatusCheckPage();
      } else {
        return const OnboardingPage();
      }
    }

    // 4. For Multi-cooperative App: if cooperative is selected -> Go to Status Check page
    if (store.hasCooperative) {
      return const StatusCheckPage();
    }

    // 5. Fallback: Go to Onboarding Page
    return const OnboardingPage();
  }
}
