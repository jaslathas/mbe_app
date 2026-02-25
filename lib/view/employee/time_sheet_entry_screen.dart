import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimesheetEntryScreen extends StatefulWidget {
  const TimesheetEntryScreen({Key? key}) : super(key: key);

  @override
  State<TimesheetEntryScreen> createState() => _TimesheetEntryScreenState();
}

class _TimesheetEntryScreenState extends State<TimesheetEntryScreen> {
  DateTime selectedDate = DateTime.now();
  String? selectedTimeSlot;
  String? selectedProjectDocId;
  String? selectedProjectName;
  String? selectedProjectCode;

  final descriptionController = TextEditingController();
  List<String> loggedSlots = [];

  final List<String> timeSlots = [
    "09:00 - 09:30",
    "09:30 - 10:00",
    "10:00 - 10:30",
    "10:30 - 11:00",
    "11:00 - 11:30",
    "11:30 - 12:00",
    "12:00 - 12:30",
    "12:30 - 01:00",
    "02:00 - 02:30",
    "02:30 - 03:00",
    "03:00 - 03:30",
    "03:30 - 04:00",
    "04:00 - 04:30",
    "04:30 - 05:00",
    "05:00 - 05:30",
    "05:30 - 06:00",
    "06:00 - 06:30",
    "06:30 - 07:00",
    "07:00 - 07:30",
    "07:30 - 08:00",
    "08:00 - 08:30",
    "08:30 - 09:00",
  ];

  @override
  void initState() {
    super.initState();
    fetchLoggedSlots();
  }

  // ================= DATE HELPERS =================

  DateTime get startOfDay =>
      DateTime(selectedDate.year, selectedDate.month, selectedDate.day);

  DateTime get endOfDay => startOfDay.add(const Duration(days: 1));

  DateTime get todayOnly {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // ================= FETCH LOGGED SLOTS =================

  Future<void> fetchLoggedSlots() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('timesheets')
        .where('userId', isEqualTo: user.uid)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    setState(() {
      loggedSlots = snapshot.docs
          .map((doc) => doc['timeSlot'] as String)
          .toList();
    });
  }

  // ================= SAVE TIMESHEET =================

  Future<void> saveTimesheet() async {
    // 🔐 BACKEND SAFETY CHECK
    if (startOfDay != todayOnly) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You can only log timesheet for today")),
      );
      return;
    }

    if (selectedTimeSlot == null ||
        selectedProjectDocId == null ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all fields")));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User data not found")));
      return;
    }

    final userName = userDoc['name'];
    final employeeCode = userDoc['employeeCode'];
    final hourlyRate = (userDoc['hourlyRate'] ?? 0).toDouble();

    const hours = 0.5;
    final totalAmount = hours * hourlyRate;

    final month =
        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}";

    await FirebaseFirestore.instance.collection('timesheets').add({
      'userId': user.uid,
      'userName': userName,
      'employeeCode': employeeCode,
      'projectId': selectedProjectDocId,
      'projectName': selectedProjectName,
      'projectCode': selectedProjectCode,
      'date': Timestamp.fromDate(startOfDay),
      'month': month,
      'timeSlot': selectedTimeSlot,
      'hours': hours,
      'description': descriptionController.text.trim(),
      'hourlyRate': hourlyRate,
      'totalAmount': totalAmount,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    descriptionController.clear();

    setState(() {
      selectedTimeSlot = null;
    });

    await fetchLoggedSlots();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Timesheet Saved")));
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Timesheet Entry")),
      body: user == null
          ? const Center(child: Text("User not logged in"))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // DATE (TODAY ONLY)
                  Row(
                    children: [
                      Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final today = DateTime.now();
                          final todayDate = DateTime(
                            today.year,
                            today.month,
                            today.day,
                          );

                          final picked = await showDatePicker(
                            context: context,
                            initialDate: todayDate,
                            firstDate: todayDate,
                            lastDate: todayDate,
                          );

                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                            });
                            fetchLoggedSlots();
                          }
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // PROJECT DROPDOWN
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('projects')
                        .where('isDeleted', isEqualTo: false)
                        .where('isActive', isEqualTo: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      if (snapshot.data!.docs.isEmpty) {
                        return const Text("No Active Projects Found");
                      }

                      final projects = snapshot.data!.docs;

                      return DropdownButtonFormField<String>(
                        value: selectedProjectDocId,
                        decoration: const InputDecoration(
                          labelText: "Select Project",
                          border: OutlineInputBorder(),
                        ),
                        items: projects.map((project) {
                          final data = project.data() as Map<String, dynamic>;

                          return DropdownMenuItem<String>(
                            value: project.id,
                            child: Text(
                              "${data['projectCode']} - ${data['projectName']}",
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          final selectedProject = projects.firstWhere(
                            (doc) => doc.id == value,
                          );

                          final data =
                              selectedProject.data() as Map<String, dynamic>;

                          setState(() {
                            selectedProjectDocId = value;
                            selectedProjectName = data['projectName'];
                            selectedProjectCode = data['projectCode'];
                          });
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // TIME SLOT
                  DropdownButtonFormField<String>(
                    value: selectedTimeSlot,
                    decoration: const InputDecoration(
                      labelText: "Select Time Slot",
                      border: OutlineInputBorder(),
                    ),
                    items: timeSlots.map((slot) {
                      final isLogged = loggedSlots.contains(slot);

                      return DropdownMenuItem(
                        value: isLogged ? null : slot,
                        enabled: !isLogged,
                        child: Text(
                          slot + (isLogged ? " (Logged)" : ""),
                          style: TextStyle(
                            color: isLogged ? Colors.grey : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTimeSlot = value;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // DESCRIPTION
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Work Description",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: saveTimesheet,
                    child: const Text("Save Timesheet"),
                  ),

                  const SizedBox(height: 30),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Today's Entries",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('timesheets')
                          .where('userId', isEqualTo: user.uid)
                          .where(
                            'date',
                            isGreaterThanOrEqualTo: Timestamp.fromDate(
                              startOfDay,
                            ),
                          )
                          .where(
                            'date',
                            isLessThan: Timestamp.fromDate(endOfDay),
                          )
                          .orderBy('date')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text("No entries logged"));
                        }

                        return ListView.builder(
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final data = snapshot.data!.docs[index];

                            return Card(
                              child: ListTile(
                                title: Text(data['timeSlot']),
                                subtitle: Text(
                                  "${data['projectName']} - ${data['description']}",
                                ),
                                trailing: Text("${data['hours']} hrs"),
                              ),
                            );
                          },
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
