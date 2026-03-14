import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DirectorMonthlyReportScreen extends StatefulWidget {
  const DirectorMonthlyReportScreen({super.key});

  @override
  State<DirectorMonthlyReportScreen> createState() =>
      _DirectorMonthlyReportScreenState();
}

class _DirectorMonthlyReportScreenState
    extends State<DirectorMonthlyReportScreen> {
  DateTime selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  @override
  Widget build(BuildContext context) {
    DateTime start = DateTime(selectedMonth.year, selectedMonth.month, 1);
    DateTime end = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

    return Padding(
      padding: const EdgeInsets.all(20),

      child: StreamBuilder<QuerySnapshot>(
        key: ValueKey("${selectedMonth.year}-${selectedMonth.month}"),

        stream: FirebaseFirestore.instance
            .collection('billing')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('date', isLessThan: Timestamp.fromDate(end))
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No billing data found"));
          }

          double totalRevenue = 0;
          double totalHours = 0;

          Map<String, double> projectRevenue = {};
          Map<String, double> employeeRevenue = {};
          Map<int, double> dailyRevenue = {};

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;

            double amount =
                double.tryParse(data['totalAmount']?.toString() ?? "0") ?? 0;

            double hours =
                double.tryParse(data['totalHours']?.toString() ?? "0") ?? 0;

            String projectId = data['projectId'] ?? "Unknown";
            String userId = data['userId'] ?? "Unknown";

            Timestamp ts = data['date'];
            DateTime date = ts.toDate();

            int day = date.day;

            totalRevenue += amount;
            totalHours += hours;

            projectRevenue[projectId] =
                (projectRevenue[projectId] ?? 0) + amount;

            employeeRevenue[userId] = (employeeRevenue[userId] ?? 0) + amount;

            dailyRevenue[day] = (dailyRevenue[day] ?? 0) + amount;
          }

          double avgRate = totalHours == 0 ? 0 : totalRevenue / totalHours;

          /// sort data
          List<MapEntry<String, double>> sortedProjects =
              projectRevenue.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

          List<MapEntry<String, double>> sortedEmployees =
              employeeRevenue.entries.toList()
                ..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            children: [
              /// HEADER
              Row(
                children: [
                  const Text(
                    "Monthly Report",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const Spacer(),

                  SizedBox(
                    width: 220,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_month),

                      label: Text(
                        DateFormat('MMMM yyyy').format(selectedMonth),
                      ),

                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedMonth,
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2030),
                        );

                        if (picked != null) {
                          setState(() {
                            selectedMonth = DateTime(
                              picked.year,
                              picked.month,
                              1,
                            );
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              /// KPI CARDS
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _card("Total Billing", "₹${totalRevenue.toStringAsFixed(0)}"),

                  _card("Total Hours", totalHours.toStringAsFixed(0)),

                  _card("Avg Rate", "₹${avgRate.toStringAsFixed(0)}"),
                ],
              ),

              const SizedBox(height: 40),

              /// DAILY CHART
              const Text(
                "Daily Revenue Trend",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              SizedBox(height: 300, child: dailyChart(dailyRevenue)),

              const SizedBox(height: 40),

              /// PROJECT CHART
              const Text(
                "Revenue by Project",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              SizedBox(height: 250, child: barChart(sortedProjects)),

              const SizedBox(height: 20),

              ...sortedProjects.map((entry) {
                return Card(
                  child: ListTile(
                    title: Text("Project: ${entry.key}"),

                    trailing: Text(
                      "₹${entry.value.toStringAsFixed(0)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 40),

              /// EMPLOYEE CHART
              const Text(
                "Revenue by Employee",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              SizedBox(height: 250, child: barChart(sortedEmployees)),

              const SizedBox(height: 20),

              ...sortedEmployees.map((entry) {
                return Card(
                  child: ListTile(
                    title: Text("Employee: ${entry.key}"),

                    trailing: Text(
                      "₹${entry.value.toStringAsFixed(0)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  /// KPI CARD
  Widget _card(String title, String value) {
    return SizedBox(
      width: 220,

      child: Card(
        elevation: 3,

        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
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

  /// DAILY CHART
  Widget dailyChart(Map<int, double> data) {
    List<MapEntry<int, double>> entries = data.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    List<FlSpot> spots = entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(spots: spots, isCurved: true, barWidth: 4),
        ],
      ),
    );
  }

  /// BAR CHART
  Widget barChart(List<MapEntry<String, double>> data) {
    return BarChart(
      BarChartData(
        barGroups: data.asMap().entries.map((e) {
          int index = e.key;
          double value = e.value.value;

          return BarChartGroupData(
            x: index,
            barRods: [BarChartRodData(toY: value, width: 16)],
          );
        }).toList(),
      ),
    );
  }
}
