import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProjectScreen extends StatefulWidget {
  final String? docId;
  final DocumentSnapshot? existingData;

  const EditProjectScreen({super.key, this.docId, this.existingData});

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController codeCtrl;
  late TextEditingController nameCtrl;
  late TextEditingController clientCtrl;

  String status = "active";
  bool isActive = true;

  @override
  void initState() {
    super.initState();

    final data = widget.existingData?.data() as Map<String, dynamic>?;

    codeCtrl = TextEditingController(text: data?['projectCode'] ?? '');
    nameCtrl = TextEditingController(text: data?['projectName'] ?? '');
    clientCtrl = TextEditingController(text: data?['clientName'] ?? '');

    status = data?['status'] ?? 'active';
    isActive = data?['isActive'] ?? true;
  }

  Future<void> saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    final projectsRef = FirebaseFirestore.instance.collection('projects');

    final data = {
      'projectCode': codeCtrl.text.trim(),
      'projectName': nameCtrl.text.trim(),
      'clientName': clientCtrl.text.trim(),
      'status': status,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (widget.docId == null) {
      data['createdAt'] = FieldValue.serverTimestamp();

      await projectsRef.doc(codeCtrl.text.trim()).set(data);
    } else {
      await projectsRef.doc(widget.docId).update(data);
    }

    // ignore: use_build_context_synchronously
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docId == null ? "Add Project" : "Edit Project"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: codeCtrl,
                decoration: const InputDecoration(labelText: "Project Code"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Project Name"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 15),
              TextFormField(
                controller: clientCtrl,
                decoration: const InputDecoration(labelText: "Client Name"),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                initialValue: status,
                items: const [
                  DropdownMenuItem(value: "active", child: Text("Active")),
                  DropdownMenuItem(
                    value: "completed",
                    child: Text("Completed"),
                  ),
                  DropdownMenuItem(value: "on-hold", child: Text("On Hold")),
                  DropdownMenuItem(value: "revision", child: Text("Revision")),
                ],
                onChanged: (v) => setState(() => status = v!),
                decoration: const InputDecoration(labelText: "Status"),
              ),
              SwitchListTile(
                value: isActive,
                onChanged: (v) => setState(() => isActive = v),
                title: const Text("Active"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: saveProject, child: const Text("Save")),
            ],
          ),
        ),
      ),
    );
  }
}
