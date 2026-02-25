import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:time_track/view/admin/edit_project_screen.dart';

class ProjectManagementScreen extends StatefulWidget {
  const ProjectManagementScreen({super.key});

  @override
  State<ProjectManagementScreen> createState() =>
      _ProjectManagementScreenState();
}

class _ProjectManagementScreenState extends State<ProjectManagementScreen> {
  String searchText = "";

  @override
  Widget build(BuildContext context) {
    final projectsRef = FirebaseFirestore.instance.collection('projects');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Project Management"),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditProjectScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search by project name or code",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  searchText = value.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: projectsRef
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final projects = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['projectName'] ?? '').toLowerCase();
                  final code = (data['projectCode'] ?? '').toLowerCase();

                  return name.contains(searchText) || code.contains(searchText);
                }).toList();

                if (projects.isEmpty) {
                  return const Center(child: Text("No Projects Found"));
                }

                return ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    final data = project.data() as Map<String, dynamic>;

                    final isActive = data['isActive'] ?? true;
                    final isDeleted = data['isDeleted'] ?? false;

                    if (isDeleted) return const SizedBox();

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Text(
                          data['projectName'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          "Code: ${data['projectCode']}\n"
                          "Client: ${data['clientName']}\n"
                          "Status: ${data['status']}\n"
                          "Active: ${isActive ? "Yes" : "No"}",
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == "edit") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditProjectScreen(
                                    docId: project.id,
                                    existingData: project,
                                  ),
                                ),
                              );
                            }

                            if (value == "toggle") {
                              await FirebaseFirestore.instance
                                  .collection('projects')
                                  .doc(project.id)
                                  .update({
                                    'isActive': !isActive,
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  });
                            }

                            if (value == "delete") {
                              await FirebaseFirestore.instance
                                  .collection('projects')
                                  .doc(project.id)
                                  .update({
                                    'isDeleted': true,
                                    'updatedAt': FieldValue.serverTimestamp(),
                                  });
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: "edit",
                              child: Text("Edit"),
                            ),
                            PopupMenuItem(
                              value: "toggle",
                              child: Text(isActive ? "Deactivate" : "Activate"),
                            ),
                            const PopupMenuItem(
                              value: "delete",
                              child: Text("Soft Delete"),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
