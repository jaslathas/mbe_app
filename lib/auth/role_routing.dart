import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:time_track/auth/login_screen.dart';
import 'package:time_track/view/admin/admin_dashboard.dart';
import 'package:time_track/view/director/director_dashboard.dart';
import 'package:time_track/view/employee/employee_home_screen.dart';
import 'package:time_track/view/no_access_screen.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final role = snapshot.data!['role'];

        if (role == 'employee') {
          return const EmployeeHomeScreen();
        } else if (role == 'admin') {
          return const AdminDashboard();
        } else if (role == 'director') {
          return const DirectorDashboard();
        } else {
          return const NoAccessScreen();
        }
      },
    );
  }
}
