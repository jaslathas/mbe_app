import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:time_track/auth/login_screen.dart';
import 'package:time_track/auth/registration_screen.dart';
import 'package:time_track/core/auth/auth_wrapper.dart';
import 'package:time_track/firebase_options.dart';

import 'package:time_track/view/admin/admin_dashboard.dart';
import 'package:time_track/view/admin/project_management_screen.dart';
import 'package:time_track/view/director/director_dashboard.dart';
import 'package:time_track/view/employee/employee_home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Time Track',

      /// ================= THEME =================
      theme: ThemeData(
        useMaterial3: true,

        /// 🏛 Architectural Grey Theme
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5E5E5E),
          brightness: Brightness.light,
        ),

        scaffoldBackgroundColor: const Color(0xFFF5F5F5),

        /// AppBar Theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF5E5E5E),
          elevation: 2,
          centerTitle: true,
        ),

        /// Elevated Button Theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF424242),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),

        /// TextButton Theme
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF5E5E5E)),
        ),

        /// Input Fields
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF5E5E5E), width: 2),
          ),
        ),

        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),

      /// ================= ENTRY POINT =================
      home: const AuthWrapper(),

      /// ================= ROUTES =================
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/employeeHome': (context) => const EmployeeHomeScreen(),
        '/adminDashboard': (context) => const AdminDashboard(),
        '/directorDashboard': (context) => const DirectorDashboard(),
        '/projectManagement': (context) => const ProjectManagementScreen(),
      },
    );
  }
}
