import 'package:flutter/material.dart';
import 'package:time_track/model/time_sheet_model.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  String selectedEmployee = 'Anu R';
  String selectedProject = 'HPCL Warehouse';
  final rateController = TextEditingController();

  double totalHours = 0;
  double totalAmount = 0;

  /// 🔹 Dummy Approved Timesheets
  final List<Timesheet> timesheets = [
    Timesheet(
      employeeName: 'Anu R',
      projectName: 'HPCL Warehouse',
      hours: 8,
      isApproved: true,
    ),
    Timesheet(
      employeeName: 'Anu R',
      projectName: 'HPCL Warehouse',
      hours: 6,
      isApproved: true,
    ),
    Timesheet(
      employeeName: 'Rahul K',
      projectName: 'Commercial Complex',
      hours: 10,
      isApproved: true,
    ),
    Timesheet(
      employeeName: 'Anu R',
      projectName: 'Commercial Complex',
      hours: 5,
      isApproved: false, // Not approved → should not count
    ),
  ];

  final List<String> employees = ['Anu R', 'Rahul K'];

  final List<String> projects = ['HPCL Warehouse', 'Commercial Complex'];

  void calculateBilling() {
    final rate = double.tryParse(rateController.text) ?? 0;

    /// 🔹 Filter approved timesheets only
    final filteredTimesheets = timesheets.where(
      (t) =>
          t.employeeName == selectedEmployee &&
          t.projectName == selectedProject &&
          t.isApproved == true,
    );

    /// 🔹 Sum hours
    totalHours = filteredTimesheets.fold(0, (sum, item) => sum + item.hours);

    totalAmount = totalHours * rate;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Billing from Timesheets')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            /// Project Dropdown
            DropdownButtonFormField<String>(
              value: selectedProject,
              decoration: const InputDecoration(labelText: 'Select Project'),
              items: projects.map((project) {
                return DropdownMenuItem(value: project, child: Text(project));
              }).toList(),
              onChanged: (value) {
                selectedProject = value!;
                calculateBilling();
              },
            ),

            const SizedBox(height: 16),

            /// Employee Dropdown
            DropdownButtonFormField<String>(
              value: selectedEmployee,
              decoration: const InputDecoration(labelText: 'Select Employee'),
              items: employees.map((employee) {
                return DropdownMenuItem(value: employee, child: Text(employee));
              }).toList(),
              onChanged: (value) {
                selectedEmployee = value!;
                calculateBilling();
              },
            ),

            const SizedBox(height: 16),

            /// Rate Input
            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Rate Per Hour (₹)'),
              onChanged: (value) => calculateBilling(),
            ),

            const SizedBox(height: 24),

            /// Total Hours
            Card(
              child: ListTile(
                title: const Text('Approved Total Hours'),
                trailing: Text(
                  totalHours.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// Total Amount
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Billing Amount',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹ ${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () {
                calculateBilling();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Billing Calculated from Approved Timesheets',
                    ),
                  ),
                );
              },
              child: const Text('Generate Bill'),
            ),
          ],
        ),
      ),
    );
  }
}
