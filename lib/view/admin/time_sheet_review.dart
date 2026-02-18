import 'package:flutter/material.dart';

class TimesheetReviewScreen extends StatelessWidget {
  const TimesheetReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timesheet Review')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// Filter Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        const Text('12 Feb 2026'),
                        const Spacer(),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Change Date'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Employee',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'anu', child: Text('Anu R')),
                        DropdownMenuItem(
                          value: 'rahul',
                          child: Text('Rahul K'),
                        ),
                      ],
                      onChanged: (value) {},
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// Timesheet List
            Expanded(
              child: ListView(
                children: const [
                  _ReviewTile(
                    slot: '09:30 – 10:00',
                    project: 'PRJ-101',
                    description: 'Column layout drafting',
                  ),
                  _ReviewTile(
                    slot: '10:00 – 10:30',
                    project: 'PRJ-102',
                    description: 'Beam detailing update',
                  ),
                  _ReviewTile(
                    slot: '10:30 – 11:00',
                    project: 'PRJ-101',
                    description: 'Foundation correction',
                  ),
                ],
              ),
            ),

            /// Summary Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Total Slots: 3',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Total Hours: 1.5',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual Review Tile
class _ReviewTile extends StatelessWidget {
  final String slot;
  final String project;
  final String description;

  const _ReviewTile({
    required this.slot,
    required this.project,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.access_time),
        title: Text(slot),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Project: $project'),
            Text(description, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
