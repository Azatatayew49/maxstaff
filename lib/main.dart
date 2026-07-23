import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MaxStaffApp());
}

class MaxStaffApp extends StatelessWidget {
  const MaxStaffApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eziz Obam Staff',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService().isLoggedIn(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snap.data == true
            ? const MainScreen()
            : const LoginScreen();
      },
    );
  }
}
