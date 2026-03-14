import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DirectorRevenueScreen extends StatelessWidget {
  const DirectorRevenueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('billing').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        Map<String, double> projectRevenue = {};

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;

          final projectId = data['projectId'] ?? "Unknown";

          double amount = double.tryParse(data['totalAmount'].toString()) ?? 0;

          projectRevenue[projectId] = (projectRevenue[projectId] ?? 0) + amount;
        }

        return ListView(
          children: projectRevenue.entries.map((entry) {
            return Card(
              child: ListTile(
                title: Text("Project ID : ${entry.key}"),
                trailing: Text(
                  "₹${entry.value.toStringAsFixed(0)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
