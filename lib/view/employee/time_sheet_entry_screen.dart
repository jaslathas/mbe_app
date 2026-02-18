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
  String? selectedProjectDocId;
  String? selectedProjectCode;
  String? selectedProjectName;
  String? selectedTimeSlot;

  DateTime selectedDate = DateTime.now();

  final TextEditingController descriptionController = TextEditingController();

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
  ];

  final user = FirebaseAuth.instance.currentUser;

  Future<void> saveTimesheet() async {
    if (selectedProjectDocId == null ||
        selectedTimeSlot == null ||
        descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }

    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    // 🔥 Duplicate Check
    final duplicateCheck = await FirebaseFirestore.instance
        .collection('timesheets')
        .where('userId', isEqualTo: user!.uid)
        .where('date', isEqualTo: formattedDate)
        .where('timeSlot', isEqualTo: selectedTimeSlot)
        .get();

    if (duplicateCheck.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Time slot already logged!")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('timesheets').add({
      'userId': user!.uid,
      'projectDocId': selectedProjectDocId,
      'projectCode': selectedProjectCode,
      'projectName': selectedProjectName,
      'date': formattedDate,
      'timeSlot': selectedTimeSlot,
      'description': descriptionController.text.trim(),
      'createdAt': Timestamp.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Timesheet saved successfully")),
    );

    setState(() {
      selectedProjectDocId = null;
      selectedProjectCode = null;
      selectedProjectName = null;
      selectedTimeSlot = null;
      descriptionController.clear();
    });
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Log Time Slot")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 📅 Date Picker
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text("Select Date"),
              subtitle: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
              onTap: pickDate,
            ),

            const SizedBox(height: 20),

            // 📁 Project Dropdown
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('projects')
                  .where('status', isEqualTo: 'active')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final projects = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: selectedProjectDocId,
                  decoration: const InputDecoration(
                    labelText: "Select Project",
                    border: OutlineInputBorder(),
                  ),
                  items: projects.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final projectCode = data['projectCode'] ?? '';
                    final projectName = data['projectName'] ?? '';

                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text("$projectCode - $projectName"),
                    );
                  }).toList(),
                  onChanged: (value) {
                    final selectedDoc = projects.firstWhere(
                      (doc) => doc.id == value,
                    );

                    final data = selectedDoc.data() as Map<String, dynamic>;

                    setState(() {
                      selectedProjectDocId = value;
                      selectedProjectCode = data['projectCode'];
                      selectedProjectName = data['projectName'];
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // ⏰ Time Slot Dropdown
            DropdownButtonFormField<String>(
              value: selectedTimeSlot,
              decoration: const InputDecoration(
                labelText: "Time Slot",
                border: OutlineInputBorder(),
              ),
              items: timeSlots.map((slot) {
                return DropdownMenuItem(value: slot, child: Text(slot));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedTimeSlot = value;
                });
              },
            ),

            const SizedBox(height: 20),

            // 📝 Description Box
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Work Description",
                hintText: "Describe what you worked on...",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            // 💾 Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saveTimesheet,
                child: const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
