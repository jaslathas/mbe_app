import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EmployeeMonthlyProjectScreen extends StatefulWidget {
  const EmployeeMonthlyProjectScreen({super.key});

  @override
  State<EmployeeMonthlyProjectScreen> createState() =>
      _EmployeeMonthlyProjectScreenState();
}

class _EmployeeMonthlyProjectScreenState
    extends State<EmployeeMonthlyProjectScreen> {
  String? selectedEmployeeId;
  String? selectedMonth;

  Map<String, double> projectHours = {};
  bool loading = false;

  final List<String> months = List.generate(
    12,
    (index) =>
        DateFormat('yyyy-MM').format(DateTime(DateTime.now().year, index + 1)),
  );

  Future<void> fetchData() async {
    if (selectedEmployeeId == null || selectedMonth == null) return;

    setState(() {
      loading = true;
      projectHours.clear();
    });

    DateTime start = DateTime.parse("$selectedMonth-01");
    DateTime end = DateTime(start.year, start.month + 1, 1);

    final query = await FirebaseFirestore.instance
        .collection('timesheets')
        .where('userId', isEqualTo: selectedEmployeeId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    for (var doc in query.docs) {
      final data = doc.data();

      String projectName = data['projectName'] ?? "Unknown";

      double hours = (data['hours'] ?? 0).toDouble();

      projectHours[projectName] = (projectHours[projectName] ?? 0) + hours;
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Employee Monthly Project Report")),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            /// EMPLOYEE DROPDOWN
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'Employee')
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text("No employees found");
                }

                final employees = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  initialValue: selectedEmployeeId,

                  decoration: const InputDecoration(
                    labelText: "Select Employee",
                    border: OutlineInputBorder(),
                  ),

                  items: employees.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    String userName =
                        data['userName'] ?? data['name'] ?? "No Name";

                    return DropdownMenuItem<String>(
                      value: doc.id,

                      child: Text(userName),
                    );
                  }).toList(),

                  onChanged: (value) {
                    setState(() {
                      selectedEmployeeId = value;
                    });

                    fetchData();
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            /// MONTH DROPDOWN
            DropdownButtonFormField<String>(
              initialValue: selectedMonth,

              decoration: const InputDecoration(
                labelText: "Select Month",
                border: OutlineInputBorder(),
              ),

              items: months.map((month) {
                return DropdownMenuItem(value: month, child: Text(month));
              }).toList(),

              onChanged: (value) {
                setState(() {
                  selectedMonth = value;
                });

                fetchData();
              },
            ),

            const SizedBox(height: 20),

            /// RESULTS
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : projectHours.isEmpty
                  ? const Center(child: Text("No data found"))
                  : ListView.builder(
                      itemCount: projectHours.length,
                      itemBuilder: (context, index) {
                        final entry = projectHours.entries.elementAt(index);

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),

                          child: ListTile(
                            title: Text(entry.key),

                            subtitle: Text("Total Hours: ${entry.value}"),

                            trailing: const Icon(Icons.work_outline),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
