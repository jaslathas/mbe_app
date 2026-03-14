import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:time_track/view/admin/monthly/admin_project_screen.dart';
import 'package:time_track/view/admin/monthly/employee_monthly_attendance.dart';

import 'add_employee_screen.dart';
import 'employee_list_screen.dart';
import 'project_management_screen.dart';
import 'monthly/admin_employee_monthly.dart';
import 'project_billing_screen.dart';
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
                      "Malabar Bureau of Engineering",
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
                _sideMenuItem(Icons.bar_chart, "Monthly employee view", 7),
                _sideMenuItem(Icons.calendar_today, "Attendance", 8),

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
                    // ignore: use_build_context_synchronously
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Text(
                      //   _getTitle(),
                      //   style: const TextStyle(
                      //     fontSize: 20,
                      //     fontWeight: FontWeight.bold,
                      //   ),
                      // ),
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
      // ignore: deprecated_member_use
      tileColor: isSelected ? Colors.blueAccent.withOpacity(0.3) : null,
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
    );
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
        return const BillingScreen();
      case 6:
        return const AdminApprovalScreen();
      case 7:
        return const EmployeeMonthlyProjectScreen();
      case 8:
        return const EmployeeMonthlyAttendance();

      default:
        return _adminDashboard();
    }
  }

  /// ================= DASHBOARD HOME =================
  Widget _adminDashboard() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('timesheets')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(firstDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(lastDay))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text("No data this month"));
        }

        /// ================= CALCULATION =================

        Map<String, dynamic> employeeData = {};
        Map<String, int> companyProjectTotals = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;

          final userId = data['userId'];
          final employeeName = data['userName'] ?? 'Unknown';
          final projectCode = data['projectCode'] ?? '';
          final projectName = data['projectName'] ?? '';
          final Timestamp timestamp = data['date'];
          final date = timestamp.toDate();

          /// Create employee container
          if (!employeeData.containsKey(userId)) {
            employeeData[userId] = {
              'name': employeeName,
              'projects': {},
              'attendance': <String>{},
              'totalSlots': 0,
            };
          }

          /// Attendance (unique days)
          employeeData[userId]['attendance'].add(
            DateFormat('yyyy-MM-dd').format(date),
          );

          /// Total slots
          employeeData[userId]['totalSlots'] += 1;

          /// Project grouping per employee
          final projects = employeeData[userId]['projects'];

          if (!projects.containsKey(projectCode)) {
            projects[projectCode] = {'name': projectName, 'slots': 0};
          }

          projects[projectCode]['slots'] += 1;

          /// Company-wide project total
          companyProjectTotals[projectCode] =
              (companyProjectTotals[projectCode] ?? 0) + 1;
        }

        /// Dynamic Working Days (Mon–Fri)
        int workingDaysInMonth = 0;
        for (int i = 0; i < lastDay.day; i++) {
          final date = DateTime(now.year, now.month, i + 1);
          if (date.weekday != DateTime.saturday &&
              date.weekday != DateTime.sunday) {
            workingDaysInMonth++;
          }
        }

        /// ================= UI =================

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "ADMIN MONTHLY OVERVIEW - ${DateFormat('MMMM yyyy').format(now).toUpperCase()}",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              /// 🔹 Employee Cards
              ...employeeData.entries.map((entry) {
                final emp = entry.value;
                final totalSlots = emp['totalSlots'];
                final totalHours = totalSlots * 0.5;
                final attendanceDays = (emp['attendance'] as Set).length;

                final attendancePercent =
                    (attendanceDays / workingDaysInMonth) * 100;

                return Card(
                  color: Colors.white,
                  // Use the shape property to define the border and corners
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      15.0,
                    ), // Rounded corners
                  ),
                  elevation: 5, //
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Total Hours: ${totalHours.toStringAsFixed(1)}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Attendance: ${attendancePercent.toStringAsFixed(1)}%",
                          style: const TextStyle(fontSize: 14),
                        ),

                        const Divider(),

                        ...emp['projects'].entries.map((p) {
                          final code = p.key;
                          final slots = p.value['slots'];
                          final hours = slots * 0.5;

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              "$code - ${p.value['name']}",
                              style: const TextStyle(fontSize: 15),
                            ),
                            trailing: Text(
                              "${hours.toStringAsFixed(1)} hrs",
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 10),

              /// 🔹 Company Project Summary
              const Text(
                "Company Project Totals",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              ...companyProjectTotals.entries.map((entry) {
                final hours = entry.value * 0.5;
                return ListTile(
                  title: Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),

                  trailing: Text(
                    "${hours.toStringAsFixed(1)} hrs",
                    style: const TextStyle(fontSize: 15),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
