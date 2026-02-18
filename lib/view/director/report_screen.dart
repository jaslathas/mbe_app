import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final monthlyRevenue = {
      "January": 120000.0,
      "February": 98000.0,
      "March": 135000.0,
    };

    final projectRevenue = {
      "HPCL Warehouse": 200000.0,
      "Commercial Complex": 150000.0,
      "Villa Project": 80000.0,
    };

    return Scaffold(
      appBar: AppBar(title: const Text("Reports")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text(
              "Monthly Revenue",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            ...monthlyRevenue.entries.map(
              (entry) => Card(
                child: ListTile(
                  title: Text(entry.key),
                  trailing: Text(
                    "₹ ${entry.value.toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Project-wise Revenue",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            ...projectRevenue.entries.map(
              (entry) => Card(
                child: ListTile(
                  title: Text(entry.key),
                  trailing: Text(
                    "₹ ${entry.value.toStringAsFixed(0)}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
