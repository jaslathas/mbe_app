import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EmployeeMonthlyAttendance extends StatefulWidget {
  const EmployeeMonthlyAttendance({super.key});

  @override
  State<EmployeeMonthlyAttendance> createState() =>
      _EmployeeMonthlyAttendanceState();
}

class _EmployeeMonthlyAttendanceState extends State<EmployeeMonthlyAttendance> {
  String? selectedUserId;
  DateTime selectedMonth = DateTime.now();

  String getStatus(double hours) {
    if (hours >= 6) return "Full";
    if (hours >= 3.5) return "Half";
    return "Absent";
  }

  @override
  Widget build(BuildContext context) {
    DateTime start = DateTime(selectedMonth.year, selectedMonth.month, 1);
    DateTime end = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

    return Scaffold(
      appBar: AppBar(title: const Text("Employee Monthly Attendance")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            /// MONTH DROPDOWN
            DropdownButtonFormField<int>(
              initialValue: selectedMonth.month,
              decoration: const InputDecoration(labelText: "Select Month"),

              items: List.generate(12, (index) {
                int month = index + 1;

                return DropdownMenuItem(
                  value: month,
                  child: Text(DateFormat.MMMM().format(DateTime(0, month))),
                );
              }),

              onChanged: (value) {
                setState(() {
                  selectedMonth = DateTime(selectedMonth.year, value!);
                });
              },
            ),

            const SizedBox(height: 20),

            /// EMPLOYEE DROPDOWN
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),

              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final users = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  initialValue: selectedUserId,
                  decoration: const InputDecoration(
                    labelText: "Select Employee",
                  ),

                  items: users.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(data['name'] ?? "Employee"),
                    );
                  }).toList(),

                  onChanged: (value) {
                    setState(() {
                      selectedUserId = value;
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 30),

            /// ATTENDANCE CARD
            if (selectedUserId != null)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('timesheets')
                      .where('userId', isEqualTo: selectedUserId)
                      .where(
                        'date',
                        isGreaterThanOrEqualTo: Timestamp.fromDate(start),
                      )
                      .where('date', isLessThan: Timestamp.fromDate(end))
                      .snapshots(),

                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final docs = snapshot.data!.docs;

                    Map<int, double> dailyHours = {};

                    for (var doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;

                      DateTime date = (data['date'] as Timestamp).toDate();
                      int day = date.day;

                      double hours = (data['hours'] ?? 0).toDouble();

                      dailyHours[day] = (dailyHours[day] ?? 0) + hours;
                    }

                    int full = 0;
                    int half = 0;
                    int absent = 0;

                    List<String> absentDates = [];

                    int daysInMonth = DateUtils.getDaysInMonth(
                      selectedMonth.year,
                      selectedMonth.month,
                    );

                    for (int d = 1; d <= daysInMonth; d++) {
                      double hours = dailyHours[d] ?? 0;

                      String status = getStatus(hours);

                      if (status == "Full") full++;
                      if (status == "Half") half++;

                      if (hours < 3.5) {
                        absent++;
                        absentDates.add(
                          DateFormat('dd MMM').format(
                            DateTime(
                              selectedMonth.year,
                              selectedMonth.month,
                              d,
                            ),
                          ),
                        );
                      }
                    }

                    return Card(
                      elevation: 4,

                      child: Padding(
                        padding: const EdgeInsets.all(20),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              "Attendance Summary",
                              style: Theme.of(context).textTheme.titleLarge,
                            ),

                            const SizedBox(height: 20),

                            Text("Full Days : $full"),
                            Text("Half Days : $half"),
                            Text("Absent Days : $absent"),

                            const SizedBox(height: 20),

                            const Text(
                              "Absent Dates",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            const SizedBox(height: 10),

                            Expanded(
                              child: ListView(
                                children: absentDates
                                    .map((d) => Text(d))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
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
