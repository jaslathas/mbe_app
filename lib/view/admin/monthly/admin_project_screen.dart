import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminProjectMonthlyScreen extends StatefulWidget {
  const AdminProjectMonthlyScreen({super.key});

  @override
  State<AdminProjectMonthlyScreen> createState() =>
      _AdminProjectMonthlyScreenState();
}

class _AdminProjectMonthlyScreenState extends State<AdminProjectMonthlyScreen> {
  String? selectedProjectId;

  // Default month (current)
  String selectedMonth =
      "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}";

  List<String> monthList = [];

  @override
  void initState() {
    super.initState();
    generateMonthList();
  }

  // ================= GENERATE MONTH LIST =================
  void generateMonthList() {
    final now = DateTime.now();

    for (int i = 0; i < 24; i++) {
      final date = DateTime(now.year, now.month - i);
      String formatted =
          "${date.year}-${date.month.toString().padLeft(2, '0')}";
      monthList.add(formatted);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Project Monthly Report")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ================= PROJECT DROPDOWN =================
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projects')
                  .where('isActive', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final projects = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  initialValue: selectedProjectId,
                  decoration: const InputDecoration(
                    labelText: "Select Project",
                    border: OutlineInputBorder(),
                  ),
                  items: projects.map((project) {
                    final data = project.data() as Map<String, dynamic>;

                    return DropdownMenuItem<String>(
                      value: project.id,
                      child: Text(data['projectName'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedProjectId = value;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // ================= MONTH DROPDOWN =================
            DropdownButtonFormField<String>(
              initialValue: selectedMonth,
              decoration: const InputDecoration(
                labelText: "Select Month",
                border: OutlineInputBorder(),
              ),
              items: monthList.map((month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(month),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedMonth = value!;
                });
              },
            ),

            const SizedBox(height: 20),

            // ================= REPORT =================
            if (selectedProjectId != null)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('timesheets')
                      .where('projectId', isEqualTo: selectedProjectId)
                      .where('month', isEqualTo: selectedMonth)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    if (docs.isEmpty) {
                      return const Center(child: Text("No data found"));
                    }

                    Map<String, Map<String, dynamic>> grouped = {};
                    double totalHours = 0;
                    double totalAmount = 0;

                    for (var doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;

                      String userName = data['userName'] ?? '';
                      double hours = (data['hours'] ?? 0).toDouble();
                      double amount = (data['totalAmount'] ?? 0).toDouble();

                      totalHours += hours;
                      totalAmount += amount;

                      if (!grouped.containsKey(userName)) {
                        grouped[userName] = {'hours': 0.0, 'amount': 0.0};
                      }

                      grouped[userName]!['hours'] += hours;
                      grouped[userName]!['amount'] += amount;
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: ListView(
                            children: grouped.entries.map((entry) {
                              return Card(
                                child: ListTile(
                                  title: Text(entry.key),
                                  subtitle: Text(
                                    "Hours: ${entry.value['hours']}",
                                  ),
                                  trailing: Text(
                                    "₹ ${entry.value['amount'].toStringAsFixed(2)}",
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const Divider(),

                        ListTile(
                          title: const Text(
                            "Total Project Hours",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: Text(
                            totalHours.toString(),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),

                        ListTile(
                          title: const Text(
                            "Total Project Billing",
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
