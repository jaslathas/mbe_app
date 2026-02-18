import 'package:flutter/material.dart';

class AddEmployeeScreen extends StatefulWidget {
  final Map<String, String>? employeeData;

  const AddEmployeeScreen({super.key, this.employeeData});

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();

  String selectedRole = 'Employee';

  @override
  void initState() {
    super.initState();

    if (widget.employeeData != null) {
      nameController.text = widget.employeeData!['name']!;
      emailController.text = widget.employeeData!['email']!;
      selectedRole = widget.employeeData!['role']!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.employeeData != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Employee' : 'Add Employee')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Employee Name'),
                validator: (value) => value!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value!.isEmpty ? 'Enter email' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'Employee', child: Text('Employee')),
                  DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  DropdownMenuItem(
                    value: 'Structural Engineer',
                    child: Text('Structural Engineer'),
                  ),
                  DropdownMenuItem(
                    value: 'Draftsman',
                    child: Text('Draftsman'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedRole = value!;
                  });
                },
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final updatedEmployee = {
                      'name': nameController.text,
                      'email': emailController.text,
                      'role': selectedRole,
                      'id':
                          widget.employeeData?['id'] ??
                          'EMP-${DateTime.now().millisecondsSinceEpoch}',
                    };

                    Navigator.pop(context, updatedEmployee);
                  }
                },
                child: Text(isEditing ? 'Update Employee' : 'Save Employee'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
