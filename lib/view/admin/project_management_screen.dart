import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectManagementScreen extends StatelessWidget {
  const ProjectManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Project Management"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showProjectDialog(context),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No Projects Found"));
          }

          final projects = snapshot.data!.docs;

          return ListView.builder(
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    project['projectName'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Code: ${project['projectCode']}\n"
                    "Client: ${project['clientName']}\n"
                    "Status: ${project['status']}",
                  ),
                  isThreeLine: true,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showProjectDialog(
                          context,
                          docId: project.id,
                          existingData: project,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('projects')
                              .doc(project.id)
                              .delete();
                        },
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

  void _showProjectDialog(
    BuildContext context, {
    String? docId,
    DocumentSnapshot? existingData,
  }) {
    final codeCtrl = TextEditingController(text: existingData?['projectCode']);
    final nameCtrl = TextEditingController(text: existingData?['projectName']);
    final clientCtrl = TextEditingController(text: existingData?['clientName']);

    String status = existingData?['status'] ?? 'active';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(docId == null ? "Add Project" : "Edit Project"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                      labelText: "Project Code",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Project Name",
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: clientCtrl,
                    decoration: const InputDecoration(labelText: "Client Name"),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: status,
                    items: const [
                      DropdownMenuItem(value: "active", child: Text("Active")),
                      DropdownMenuItem(
                        value: "completed",
                        child: Text("Completed"),
                      ),
                      DropdownMenuItem(
                        value: "on-hold",
                        child: Text("On Hold"),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        status = value!;
                      });
                    },
                    decoration: const InputDecoration(labelText: "Status"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (codeCtrl.text.isEmpty ||
                      nameCtrl.text.isEmpty ||
                      clientCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("All fields required")),
                    );
                    return;
                  }

                  final projectsRef = FirebaseFirestore.instance.collection(
                    'projects',
                  );

                  try {
                    if (docId == null) {
                      // ADD
                      await projectsRef.add({
                        'projectCode': codeCtrl.text.trim(),
                        'projectName': nameCtrl.text.trim(),
                        'clientName': clientCtrl.text.trim(),
                        'status': status,
                        'createdAt': FieldValue.serverTimestamp(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Project Added Successfully"),
                        ),
                      );
                    } else {
                      // UPDATE
                      await projectsRef.doc(docId).update({
                        'projectCode': codeCtrl.text.trim(),
                        'projectName': nameCtrl.text.trim(),
                        'clientName': clientCtrl.text.trim(),
                        'status': status,
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Project Updated Successfully"),
                        ),
                      );
                    }

                    Navigator.pop(context);
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }
}
