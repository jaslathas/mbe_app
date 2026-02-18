import 'package:flutter/material.dart';

class MyTimesheetsScreen extends StatelessWidget {
  const MyTimesheetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Timesheets')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            /// Date Header
            _DateSection(
              date: '12 Feb 2026',
              entries: const [
                _TimesheetTile(
                  slot: '09:30 – 10:00',
                  project: 'PRJ-101',
                  description: 'Column layout preparation',
                ),
                _TimesheetTile(
                  slot: '10:00 – 10:30',
                  project: 'PRJ-102',
                  description: 'Beam detailing',
                ),
                _TimesheetTile(
                  slot: '10:30 – 11:00',
                  project: 'PRJ-101',
                  description: 'Foundation drawing update',
                ),
              ],
            ),

            const SizedBox(height: 20),

            _DateSection(
              date: '11 Feb 2026',
              entries: const [
                _TimesheetTile(
                  slot: '02:00 – 02:30',
                  project: 'PRJ-099',
                  description: 'Slab reinforcement drafting',
                ),
                _TimesheetTile(
                  slot: '02:30 – 03:00',
                  project: 'PRJ-099',
                  description: 'Section detailing',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Date-wise Section
class _DateSection extends StatelessWidget {
  final String date;
  final List<_TimesheetTile> entries;

  const _DateSection({required this.date, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Date title
            Text(
              date,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const Divider(),

            /// Timesheet entries
            ...entries,
          ],
        ),
      ),
    );
  }
}

/// Single Timesheet Entry Tile
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
