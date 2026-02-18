import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:time_track/view/admin/time_sheet_review.dart';
import 'project_management_screen.dart';
import 'employee_list_screen.dart';
import 'billing_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            /// Welcome
            Text(
              'Welcome, Admin 👋',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            const Text(
              'Manage projects, employees and timesheets',
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            /// Navigation Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _DashboardCard(
                  icon: Icons.work_outline,
                  title: 'Projects',
                  subtitle: 'Manage projects',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProjectManagementScreen(),
                      ),
                    );
                  },
                ),
                _DashboardCard(
                  icon: Icons.people_outline,
                  title: 'Employees',
                  subtitle: 'View staff',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EmployeeListScreen(),
                      ),
                    );
                  },
                ),
                _DashboardCard(
                  icon: Icons.access_time,
                  title: 'Timesheets',
                  subtitle: 'View & approve',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TimesheetReviewScreen(),
                      ),
                    );
                  },
                ),
                _DashboardCard(
                  icon: Icons.receipt_long,
                  title: 'Billing',
                  subtitle: 'Calculate billing',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BillingScreen()),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// Today Overview (Dynamic)
            const Text(
              'Today’s Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            FutureBuilder(
              future: _getDashboardStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stats = snapshot.data as Map<String, int>;

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          label: 'Active Projects',
                          value: stats['projects'].toString(),
                        ),
                        _StatItem(
                          label: 'Employees',
                          value: stats['employees'].toString(),
                        ),
                        _StatItem(
                          label: 'Logs Today',
                          value: stats['logsToday'].toString(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            /// Recent Activity
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('timesheets')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final logs = snapshot.data!.docs;

                if (logs.isEmpty) {
                  return const Text("No recent activity");
                }

                return Column(
                  children: logs.map((log) {
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(log['description'] ?? ''),
                        subtitle: Text("${log['date']} | ${log['timeSlot']}"),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Fetch Stats
  Future<Map<String, int>> _getDashboardStats() async {
    final projects = await FirebaseFirestore.instance
        .collection('projects')
        .where('status', isEqualTo: 'active')
        .get();

    final employees = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'employee')
        .get();

    final today = DateTime.now().toString().substring(0, 10);

    final logsToday = await FirebaseFirestore.instance
        .collection('timesheets')
        .where('date', isEqualTo: today)
        .get();

    return {
      'projects': projects.size,
      'employees': employees.size,
      'logsToday': logsToday.size,
    };
  }
}

class _DashboardCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
