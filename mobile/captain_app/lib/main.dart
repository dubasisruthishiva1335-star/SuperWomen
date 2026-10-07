import 'package:flutter/material.dart';
import 'constants/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/navigation_screen.dart';
import 'screens/earnings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CaptainSuperWomenApp());
}

class CaptainSuperWomenApp extends StatelessWidget {
  const CaptainSuperWomenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Captain SuperWomen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const CaptainDashboardScreen(),
      routes: {
        '/login': (context) => const CaptainLoginScreen(),
        '/dashboard': (context) => const CaptainDashboardScreen(),
        '/navigation': (context) => const CaptainNavigationScreen(),
        '/earnings': (context) => const CaptainEarningsScreen(),
      },
    );
  }
}
