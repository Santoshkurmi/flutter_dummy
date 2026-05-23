import 'package:flutter/material.dart';
import 'store/auth_store.dart';
import 'pages/onboarding_page.dart';
import 'pages/status_check_page.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Auth Store (persistences and initial loadings)
  final authStore = AuthStore();
  await authStore.init();

  runApp(const BrightBankApp());
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
          title: 'Bright Sahakari',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: isDark ? Brightness.dark : Brightness.light,
            scaffoldBackgroundColor: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF2563EB),
              brightness: isDark ? Brightness.dark : Brightness.light,
              surface: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
            ),
            fontFamily: 'Roboto',
          ),
          home: const InitialRouter(),
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
