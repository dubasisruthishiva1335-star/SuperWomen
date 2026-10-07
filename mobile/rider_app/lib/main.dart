import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SuperWomenRiderApp());
}

class SuperWomenRiderApp extends StatelessWidget {
  const SuperWomenRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuperWomen Rider',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF6A2CEA),
        scaffoldBackgroundColor: const Color(0xFFF8F5FD),
        fontFamily: 'PlusJakartaSans',
      ),
      home: const RiderHomeScreen(),
    );
  }
}
