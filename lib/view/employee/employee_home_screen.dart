import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
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
                      "SlotLog",
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
        return _logsView();
      case 3:
        return const EmployeeProfileScreen();
      default:
        return _dashboardView();
    }
  }

  /// ================= DASHBOARD =================
  Widget _dashboardView() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('timesheets')
          .where('employeeUid', isEqualTo: user!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data!.docs;
        final totalSlots = logs.length;
        final totalHours = totalSlots * 0.5;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome back 👋",
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                _infoCard("Total Slots", totalSlots.toString()),
                const SizedBox(width: 20),
                _infoCard("Total Hours", totalHours.toStringAsFixed(1)),
              ],
            ),
          ],
        );
      },
    );
  }

  /// ================= MY LOGS =================
  Widget _logsView() {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('timesheets')
          .where('employeeId', isEqualTo: user!.uid)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final logs = snapshot.data!.docs;

        if (logs.isEmpty) {
          return const Center(child: Text("No logs found"));
        }

        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final doc = logs[index];
            final timestamp = (doc['timestamp'] as Timestamp?)?.toDate();
            final formattedDate = timestamp != null
                ? DateFormat('dd MMM yyyy – hh:mm a').format(timestamp)
                : "";

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(doc['timeSlot'] ?? ''),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc['projectName'] ?? ''),
                    if (doc['description'] != null)
                      Text(
                        doc['description'],
                        style: const TextStyle(color: Colors.grey),
                      ),
                    Text(formattedDate, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            );
          },
        );
      },
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
                  fontSize: 24,
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
