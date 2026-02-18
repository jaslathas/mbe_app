import 'package:flutter/material.dart';
import 'package:time_track/core/constants/app_colors.dart';

class EmployeeProfileScreen extends StatelessWidget {
  const EmployeeProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            /// Profile Avatar
            const CircleAvatar(
              radius: 45,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),

            const SizedBox(height: 16),

            /// Name
            const Text(
              'Anu R',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            /// Role
            const Text(
              'Structural Draftsman',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            /// Profile Info Card
            Card(
              child: Column(
                children: const [
                  ListTile(
                    leading: Icon(Icons.email),
                    title: Text('Email'),
                    subtitle: Text('anu@example.com'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.badge),
                    title: Text('Employee ID'),
                    subtitle: Text('EMP-003'),
                  ),
                ],
              ),
            ),

            const Spacer(),

            /// Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  'LOGOUT',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
