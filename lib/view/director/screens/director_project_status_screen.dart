import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DirectorProjectStatusScreen extends StatelessWidget {
  const DirectorProjectStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('projects').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final projects = snapshot.data!.docs;

        return ListView.builder(
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final data = projects[index].data() as Map<String, dynamic>;

            return Card(
              child: ListTile(
                title: Text(data['projectName'] ?? ""),

                subtitle: Text("Client : ${data['clientName'] ?? ""}"),

                trailing: Text(data['status'] ?? "Active"),
              ),
            );
          },
        );
      },
    );
  }
}
