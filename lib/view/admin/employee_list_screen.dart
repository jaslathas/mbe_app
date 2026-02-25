import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmployeeListScreen extends StatelessWidget {
  const EmployeeListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final usersRef = FirebaseFirestore.instance.collection('users');

    return Scaffold(
      appBar: AppBar(title: const Text("Employees")),
      body: StreamBuilder<QuerySnapshot>(
        stream: usersRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Employees Found"));
          }

          final employees = snapshot.data!.docs;

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final doc = employees[index];

              // ✅ SAFE DATA EXTRACTION
              final data = doc.data() as Map<String, dynamic>? ?? {};

              final name = data['name'] ?? 'No Name';
              final email = data.containsKey('email')
                  ? data['email']
                  : 'No Email';
              final role = data['role'] ?? 'No Role';
              final rate = data['hourlyRate'] ?? 0;
              final isActive = data['isActive'] ?? true;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isActive ? Colors.green : Colors.red,
                    child: Text(
                      name.toString().isNotEmpty
                          ? name.toString()[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(name.toString()),
                  subtitle: Text("$email\nRole: $role | Rate: ₹$rate"),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        _showEditDialog(context, doc.id, data);
                      } else if (value == 'toggle') {
                        await usersRef.doc(doc.id).update({
                          'isActive': !isActive,
                        });
                      } else if (value == 'delete') {
                        await usersRef.doc(doc.id).delete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text("Edit")),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(isActive ? "Deactivate" : "Activate"),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text("Delete (Firestore Only)"),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// EDIT EMPLOYEE DIALOG
  ////////////////////////////////////////////////////////////

  void _showEditDialog(
    BuildContext context,
    String docId,
    Map<String, dynamic> data,
  ) {
    final nameController = TextEditingController(text: data['name'] ?? '');
    final rateController = TextEditingController(
      text: data['hourlyRate']?.toString() ?? '0',
    );

    String role = data['role'] ?? 'Employee';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Employee"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: rateController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Hourly Rate"),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: role,
              items: const [
                DropdownMenuItem(value: 'Employee', child: Text("Employee")),
                DropdownMenuItem(value: 'Admin', child: Text("Admin")),
                DropdownMenuItem(value: 'Director', child: Text("Director")),
              ],
              onChanged: (val) {
                role = val ?? 'Employee';
              },
              decoration: const InputDecoration(labelText: "Role"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(docId)
                  .update({
                    'name': nameController.text.trim(),
                    'hourlyRate': double.tryParse(rateController.text) ?? 0,
                    'role': role,
                  });

              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
}
