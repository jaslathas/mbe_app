import 'package:flutter/material.dart';

class DirectorDashboard extends StatelessWidget {
  const DirectorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy Data (Replace with real service later)
    final double totalRevenue = 450000;
    final int activeProjects = 5;
    final int completedProjects = 8;
    final double pendingRevenue = 120000;

    return Scaffold(
      appBar: AppBar(title: const Text("Director Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            /// KPI CARDS
            Row(
              children: [
                Expanded(
                  child: _kpiCard(
                    title: "Total Revenue",
                    value: "₹ ${totalRevenue.toStringAsFixed(0)}",
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _kpiCard(
                    title: "Pending Revenue",
                    value: "₹ ${pendingRevenue.toStringAsFixed(0)}",
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _kpiCard(
                    title: "Active Projects",
                    value: activeProjects.toString(),
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _kpiCard(
                    title: "Completed Projects",
                    value: completedProjects.toString(),
                    color: Colors.purple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            /// PROJECT STATUS SECTION
            const Text(
              "Project Status",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _projectStatusTile("HPCL Warehouse", "Completed", Colors.green),
            _projectStatusTile(
              "Commercial Complex",
              "In Progress",
              Colors.blue,
            ),
            _projectStatusTile(
              "Villa Project",
              "Pending Approval",
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _projectStatusTile(String name, String status, Color color) {
    return Card(
      child: ListTile(
        title: Text(name),
        trailing: Text(
          status,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
