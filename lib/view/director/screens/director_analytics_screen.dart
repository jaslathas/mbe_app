import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class DirectorAnalyticsScreen extends StatelessWidget {
  const DirectorAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('billing').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        double totalRevenue = 0;
        double totalHours = 0;

        Map<int, double> monthlyRevenue = {};
        Map<String, double> projectRevenue = {};
        Map<String, double> employeeRevenue = {};

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;

          /// SAFE DATA READ
          double amount = double.tryParse(data['totalAmount'].toString()) ?? 0;

          double hours = double.tryParse(data['totalHours'].toString()) ?? 0;

          String projectId = data['projectId'] ?? "Unknown";
          String userId = data['userId'] ?? "Unknown";

          Timestamp? ts = data['date'];
          DateTime date = ts?.toDate() ?? DateTime.now();

          int month = date.month;

          totalRevenue += amount;
          totalHours += hours;

          /// MONTHLY REVENUE
          monthlyRevenue[month] = (monthlyRevenue[month] ?? 0) + amount;

          /// PROJECT REVENUE
          projectRevenue[projectId] = (projectRevenue[projectId] ?? 0) + amount;

          /// EMPLOYEE REVENUE
          employeeRevenue[userId] = (employeeRevenue[userId] ?? 0) + amount;
        }

        double avgRate = totalHours == 0 ? 0 : totalRevenue / totalHours;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// KPI CARDS
              Row(
                children: [
                  _card("Total Revenue", totalRevenue),

                  const SizedBox(width: 20),

                  _card("Total Hours", totalHours),

                  const SizedBox(width: 20),

                  _card("Average Rate", avgRate),
                ],
              ),

              const SizedBox(height: 40),

              /// MONTHLY REVENUE CHART
              const Text(
                "Monthly Revenue",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 300,

                child: LineChart(
                  LineChartData(
                    borderData: FlBorderData(show: true),

                    lineBarsData: [
                      LineChartBarData(
                        spots: monthlyRevenue.entries
                            .map((e) => FlSpot(e.key.toDouble(), e.value))
                            .toList(),

                        isCurved: true,

                        barWidth: 4,

                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              /// PROJECT REVENUE
              const Text(
                "Revenue by Project",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              ...projectRevenue.entries.map((entry) {
                return Card(
                  child: ListTile(
                    title: Text("Project ID: ${entry.key}"),
                    trailing: Text(
                      "₹${entry.value.toStringAsFixed(0)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 30),

              /// EMPLOYEE BILLING
              const Text(
                "Employee Billing",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              ...employeeRevenue.entries.map((entry) {
                return Card(
                  child: ListTile(
                    title: Text("User ID: ${entry.key}"),
                    trailing: Text(
                      "₹${entry.value.toStringAsFixed(0)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _card(String title, double value) {
    return Expanded(
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                "₹${value.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 20,
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
