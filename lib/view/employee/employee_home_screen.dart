import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:time_track/view/employee/time_sheet_entry_screen.dart';

class EmployeeHomeScreen extends StatelessWidget {
  const EmployeeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = DateTime(today.year, today.month, today.day, 23, 59, 59);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SlotLog'),
        actions: [
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('timesheets')
              .where('employeeId', isEqualTo: user!.uid)
              .where(
                'date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
              )
              .where('date', isLessThanOrEqualTo: Timestamp.fromDate(todayEnd))
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final logs = snapshot.data!.docs;
            final totalSlots = logs.length;
            final totalHours = totalSlots * 0.5;

            return ListView(
              children: [
                /// Greeting
                Text(
                  'Good Morning, ${user.email!.split('@')[0]} 👋',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Today: ${DateFormat('dd MMM yyyy').format(today)}',
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 20),

                /// Log Button Card
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Log Current Slot',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TimesheetEntryScreen(),
                                ),
                              );
                            },
                            child: const Text('LOG TIME SLOT'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// Today Summary
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryItem(
                          label: 'Logged Slots',
                          value: '$totalSlots / 18',
                        ),
                        _SummaryItem(
                          label: 'Total Time',
                          value: '${totalHours.toStringAsFixed(1)} h',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// Recent Logs
                const Text(
                  'Today Logs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                if (logs.isEmpty)
                  const Text(
                    "No logs yet today",
                    style: TextStyle(color: Colors.grey),
                  ),

                ...logs.map((doc) {
                  return _RecentLogTile(
                    time: doc['timeSlot'],
                    project: doc['projectName'] ?? '',
                  );
                }).toList(),

                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Summary Item
class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({required this.label, required this.value});

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

/// Recent Log Tile
class _RecentLogTile extends StatelessWidget {
  final String time;
  final String project;

  const _RecentLogTile({required this.time, required this.project});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.access_time),
        title: Text(time),
        subtitle: Text(project),
      ),
    );
  }
}
