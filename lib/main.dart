import 'package:flutter/material.dart';
import 'store/auth_store.dart';
import 'pages/onboarding_page.dart';
import 'pages/select_cooperative_page.dart';
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
    return MaterialApp(
      title: 'Bright Sahakari',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF020617),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
          background: const Color(0xFF020617),
        ),
        fontFamily: 'Roboto',
      ),
      home: const InitialRouter(),
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

    // 1. If no cooperative selected yet -> Onboarding Page
    if (!store.hasCooperative) {
      return const OnboardingPage();
    }

    // 2. If authenticated -> Go directly to the Banking Dashboard
    if (store.isAuthenticated) {
      return const DashboardPage();
    }

    // 3. If cooperative selected but not logged in -> Go to PIN entry / Login
    final mobile = store.mobile;
    if (mobile != null && mobile.isNotEmpty) {
      return LoginPage(mobileNumber: mobile);
    }

    // Fallback: Boot into cooperative selection
    return const SelectCooperativePage();
  }
}
