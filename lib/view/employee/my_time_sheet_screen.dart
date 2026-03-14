import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyTimesheetsScreen extends StatelessWidget {
  const MyTimesheetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Timesheets')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('timesheets')
            .where('userId', isEqualTo: user.uid)
            .orderBy('date', descending: true) // SAFE single orderBy
            .snapshots(),
        builder: (context, snapshot) {
          /// 🔄 LOADING STATE
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          /// ❌ ERROR STATE
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          /// 📭 EMPTY STATE
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No timesheets found"));
          }

          final docs = snapshot.data!.docs;

          /// 🗂 GROUP BY DATE
          Map<String, List<QueryDocumentSnapshot>> groupedData = {};

          for (var doc in docs) {
            final Timestamp timestamp = doc['date'];
            final DateTime dateTime = timestamp.toDate();

            final String formattedDate = DateFormat(
              'dd MMM yyyy',
            ).format(dateTime);

            if (!groupedData.containsKey(formattedDate)) {
              groupedData[formattedDate] = [];
            }

            groupedData[formattedDate]!.add(doc);
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: groupedData.entries.map((entry) {
                return _DateSection(
                  date: entry.key,
                  entries: entry.value.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return _TimesheetTile(
                      slot: data['timeSlot'] ?? '',
                      project: data['projectCode'] ?? '',
                      description: data['description'] ?? '',
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

/// 📅 Date Section Widget
class _DateSection extends StatelessWidget {
  final String date;
  final List<_TimesheetTile> entries;

  const _DateSection({required this.date, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                date,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              ...entries,
            ],
          ),
        ),
      ),
    );
  }
}

/// ⏰ Single Entry Tile
class _TimesheetTile extends StatelessWidget {
  final String slot;
  final String project;
  final String description;

  const _TimesheetTile({
    required this.slot,
    required this.project,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.access_time),
      title: Text(slot),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Project: $project'),
          Text(description, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
