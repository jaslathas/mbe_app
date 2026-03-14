import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:time_track/view/employee/my_time_sheet_screen.dart';
import 'package:time_track/view/employee/profile_screen.dart';
import 'package:time_track/view/employee/time_sheet_entry_screen.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
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
                _sideMenuItem(Icons.access_time, "Log Time", 1),
                _sideMenuItem(Icons.list_alt, "My Logs", 2),
                _sideMenuItem(Icons.person, "Profile", 3),

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
                          IconButton(
                            icon: const Icon(Icons.person_outline),
                            onPressed: () {
                              setState(() {
                                selectedIndex = 3;
                              });
                            },
                          ),
                          Text(user?.email ?? ""),
                        ],
                      ),
                    ],
                  ),
                ),

                /// Content
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

  /// ================= PAGE TITLE =================
  String _getTitle() {
    switch (selectedIndex) {
      case 1:
        return "Log Time Slot";
      case 2:
        return "My Logs";
      case 3:
        return "My Profile";
      default:
        return "Dashboard";
    }
  }

  /// ================= PAGE SWITCH =================
  Widget _getPageContent() {
    switch (selectedIndex) {
      case 1:
        return const TimesheetEntryScreen();
      case 2:
        return MyTimesheetsScreen();
      case 3:
        return const EmployeeProfileScreen();
      default:
        return _dashboardView();
    }
  }

  /// ================= DASHBOARD =================
  /// ================= DASHBOARD =================
  Widget _dashboardView() {
    final user = FirebaseAuth.instance.currentUser;

    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('timesheets')
          .where('userId', isEqualTo: user!.uid) // ✅ unified field
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(firstDayOfMonth),
          )
          .where(
            'date',
            isLessThanOrEqualTo: Timestamp.fromDate(lastDayOfMonth),
          )
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return const Center(child: Text("No data for this month"));
        }

        /// ================= CALCULATIONS =================

        Map<String, Map<String, dynamic>> projectData = {};
        Set<String> attendanceDays = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;

          final projectCode = data['projectCode'] ?? '';
          final projectName = data['projectName'] ?? '';
          final Timestamp timestamp = data['date'];
          final date = timestamp.toDate();

          // Attendance unique days
          attendanceDays.add("${date.year}-${date.month}-${date.day}");

          // Project-wise grouping
          if (!projectData.containsKey(projectCode)) {
            projectData[projectCode] = {'name': projectName, 'slots': 0};
          }

          projectData[projectCode]!['slots'] += 1;
        }

        final totalSlots = docs.length;
        final totalHours = totalSlots * 0.5;
        final workingDays = attendanceDays.length;

        const expectedWorkingDays = 25;
        final attendancePercent = (workingDays / expectedWorkingDays) * 100;

        /// ================= UI =================

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "MONTHLY SUMMARY - ${DateFormat('MMMM yyyy').format(now).toUpperCase()}",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              /// 🔹 PROJECT SUMMARY
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: projectData.entries.map((entry) {
                      final code = entry.key;
                      final name = entry.value['name'];
                      final slots = entry.value['slots'];
                      final hours = slots * 0.5;

                      return ListTile(
                        title: Text(
                          "$code - $name",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        trailing: Text(
                          "${hours.toStringAsFixed(1)} hrs",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// 🔹 ATTENDANCE
              const Text(
                "ATTENDANCE SUMMARY",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        "Working Days: $workingDays",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Divider(thickness: 1),
                      Text(
                        "Total Hours: ${totalHours.toStringAsFixed(1)} hrs",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Divider(thickness: 1),
                      Text(
                        "Attendance: ${attendancePercent.toStringAsFixed(1)}%",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
