import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:time_track/view/director/screens/director_analytics_screen.dart';
import 'package:time_track/view/director/screens/director_report_screen.dart';
import 'package:time_track/view/director/screens/director_revenue_screen.dart';

import 'screens/director_financial_dashboard.dart';

import 'screens/director_project_status_screen.dart';

class DirectorDashboard extends StatefulWidget {
  const DirectorDashboard({super.key});

  @override
  State<DirectorDashboard> createState() => _DirectorDashboardState();
}

class _DirectorDashboardState extends State<DirectorDashboard> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Row(
        children: [
          /// SIDEBAR
          Container(
            width: 250,
            color: const Color(0xFF1E1E2D),
            child: Column(
              children: [
                const SizedBox(height: 30),

                Image.asset("assets/logo_final.png", height: 50),

                const SizedBox(height: 10),

                const Text(
                  "SlotLog Director",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),

                _sideMenuItem(Icons.dashboard, "Dashboard", 0),
                _sideMenuItem(Icons.bar_chart, "Reports", 1),
                _sideMenuItem(Icons.currency_rupee, "Revenue", 2),
                _sideMenuItem(Icons.engineering, "Project Status", 3),
                _sideMenuItem(Icons.analytics, "Analytics", 4),

                const Spacer(),

                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white70),
                  title: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.white70),
                  ),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    // ignore: use_build_context_synchronously
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          /// MAIN CONTENT
          Expanded(
            child: Column(
              children: [
                /// TOP BAR
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 4),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getTitle(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Row(
                        children: [
                          const Icon(Icons.account_circle),
                          const SizedBox(width: 8),
                          Text(user?.email ?? ""),
                        ],
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    color: const Color(0xFFF4F6FA),
                    child: _getPage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideMenuItem(IconData icon, String title, int index) {
    final isSelected = selectedIndex == index;

    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
      title: Text(
        title,
        style: TextStyle(color: isSelected ? Colors.white : Colors.white70),
      ),
      // ignore: deprecated_member_use
      tileColor: isSelected ? Colors.blueAccent.withOpacity(.3) : null,
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
    );
  }

  String _getTitle() {
    switch (selectedIndex) {
      case 1:
        return "Reports";

      case 2:
        return "Revenue";

      case 3:
        return "Project Status";
      case 4:
        return "Analytics";

      default:
        return "Director Dashboard";
    }
  }

  Widget _getPage() {
    switch (selectedIndex) {
      case 1:
        return const DirectorMonthlyReportScreen();

      case 2:
        return const DirectorRevenueScreen();

      case 3:
        return const DirectorProjectStatusScreen();
      case 4:
        return const DirectorAnalyticsScreen();

      default:
        return const DirectorFinancialDashboard();
    }
  }
}
