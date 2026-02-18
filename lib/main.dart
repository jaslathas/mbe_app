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

void main() async {
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

      // 🔥 App Entry Point
      home: const AuthWrapper(),

      // 🔥 Named Routes
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/employeeHome': (context) => const EmployeeHomeScreen(),
        '/adminDashboard': (context) => const AdminDashboardScreen(),
        '/directorDashboard': (context) => const DirectorDashboard(),
      },
    );
  }
}
