import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:time_track/view/admin/monthly/admin_project_screen.dart';

import 'add_employee_screen.dart';
import 'employee_list_screen.dart';
import 'project_management_screen.dart';
import 'monthly/admin_employee_monthly.dart';
import 'billing_screen.dart';
import 'admin_approval_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Row(
        children: [
          /// ================= SIDEBAR =================
          Container(
            width: 250,
            color: const Color(0xFF1E1E2D),
            child: Column(
              children: [
                const SizedBox(height: 30),

                /// Logo + Title
                Column(
                  children: [
                    Image.asset("assets/logo_final.png", height: 50),
                    const SizedBox(height: 10),
                    const Text(
                      "SlotLog Admin",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                _sideMenuItem(Icons.dashboard, "Dashboard", 0),
                _sideMenuItem(Icons.person_add, "Add Employee", 1),
                _sideMenuItem(Icons.people, "Manage Employees", 2),
                _sideMenuItem(Icons.add_box, "Projects", 3),
                _sideMenuItem(Icons.calendar_month, "Monthly View", 4),
                _sideMenuItem(Icons.attach_money, "Billing", 5),
                _sideMenuItem(Icons.check_circle, "Approvals", 6),

                const Spacer(),

                /// Logout
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white70),
                  title: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.white70),
                  ),
                  onTap: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          /// ================= MAIN CONTENT =================
          Expanded(
            child: Column(
              children: [
                /// Top Bar
                Container(
                  height: 70,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(blurRadius: 4, color: Colors.black12),
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
                          const Icon(Icons.admin_panel_settings),
                          const SizedBox(width: 8),
                          Text(user?.email ?? ""),
                        ],
                      ),
                    ],
                  ),
                ),

                /// Page Content
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    color: const Color(0xFFF4F6FA),
                    child: _getPageContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ================= SIDEBAR ITEM =================
  Widget _sideMenuItem(IconData icon, String title, int index) {
    final isSelected = selectedIndex == index;

    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70),
      title: Text(
        title,
        style: TextStyle(color: isSelected ? Colors.white : Colors.white70),
      ),
      tileColor: isSelected ? Colors.blueAccent.withOpacity(0.3) : null,
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
    );
  }

  /// ================= PAGE TITLE =================
  String _getTitle() {
    switch (selectedIndex) {
      case 1:
        return "Add Employee";
      case 2:
        return "Manage Employees";
      case 3:
        return "Project Management";
      case 4:
        return "Employee Monthly View";
      case 5:
        return "Billing";
      case 6:
        return "Approvals";
      default:
        return "Admin Dashboard";
    }
  }

  /// ================= PAGE SWITCH =================
  Widget _getPageContent() {
    switch (selectedIndex) {
      case 1:
        return const AddEmployeeScreen();
      case 2:
        return const EmployeeListScreen();
      case 3:
        return const ProjectManagementScreen();
      case 4:
        return const AdminProjectMonthlyScreen();
      case 5:
        return const AdminBillingScreen();
      case 6:
        return const AdminApprovalScreen();
      default:
        return _dashboardView();
    }
  }

  /// ================= DASHBOARD HOME =================
  Widget _dashboardView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome Admin 👋",
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            _infoCard("Employees", "Manage Staff"),
            const SizedBox(width: 20),
            _infoCard("Projects", "Manage Projects"),
          ],
        ),
      ],
    );
  }

  /// ================= INFO CARD =================
  Widget _infoCard(String title, String value) {
    return Expanded(
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
