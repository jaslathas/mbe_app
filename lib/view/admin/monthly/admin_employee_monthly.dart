import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminEmployeeMonthlyScreen extends StatefulWidget {
  const AdminEmployeeMonthlyScreen({Key? key}) : super(key: key);

  @override
  State<AdminEmployeeMonthlyScreen> createState() =>
      _AdminEmployeeMonthlyScreenState();
}

class _AdminEmployeeMonthlyScreenState
    extends State<AdminEmployeeMonthlyScreen> {
  String? selectedEmployeeId;

  String selectedMonth =
      "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Employee Monthly Report")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ================= EMPLOYEE DROPDOWN =================
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('role', isEqualTo: 'employee')
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final employees = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  value: selectedEmployeeId,
                  decoration: const InputDecoration(
                    labelText: "Select Employee",
                    border: OutlineInputBorder(),
                  ),
                  items: employees.map((emp) {
                    final data = emp.data() as Map<String, dynamic>;

                    final name = data['name'] ?? "No Name";
                    final code = data['employeeCode'] ?? "No Code";

                    return DropdownMenuItem<String>(
                      value: emp.id,
                      child: Text("$name ($code)"),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedEmployeeId = value;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // ================= MONTH SELECT =================
            Row(
              children: [
                Text("Month: $selectedMonth"),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.calendar_month),
                  onPressed: () async {
                    final now = DateTime.now();

                    final picked = await showDatePicker(
                      context: context,
                      initialDate: now,
                      firstDate: DateTime(2023),
                      lastDate: now,
                    );

                    if (picked != null) {
                      setState(() {
                        selectedMonth =
                            "${picked.year}-${picked.month.toString().padLeft(2, '0')}";
                      });
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ================= REPORT SECTION =================
            if (selectedEmployeeId != null)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('timesheets')
                      .where('employeeUid', isEqualTo: selectedEmployeeId)
                      .where('month', isEqualTo: selectedMonth)
                      .where('status', isEqualTo: 'approved')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return const Center(child: Text("No data found"));
                    }

                    Map<String, double> projectHours = {};
                    double totalHours = 0;
                    double totalAmount = 0;

                    for (var doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;

                      String projectName = data['projectName'] ?? "Unknown";

                      double hours = (data['hours'] ?? 0).toDouble();

                      double amount = (data['totalAmount'] ?? 0).toDouble();

                      totalHours += hours;
                      totalAmount += amount;

                      if (!projectHours.containsKey(projectName)) {
                        projectHours[projectName] = 0;
                      }

                      projectHours[projectName] =
                          projectHours[projectName]! + hours;
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: ListView(
                            children: projectHours.entries.map((e) {
                              return Card(
                                child: ListTile(
                                  title: Text(e.key),
                                  subtitle: Text("Hours: ${e.value}"),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const Divider(),

                        ListTile(
                          title: const Text(
                            "Total Hours",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Text(
                            totalHours.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),

                        ListTile(
                          title: const Text(
                            "Total Billing",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Text(
                            "₹ ${totalAmount.toStringAsFixed(2)}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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
