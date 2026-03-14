import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DirectorFinancialDashboard extends StatelessWidget {
  const DirectorFinancialDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('billing').snapshots(),
      builder: (context, billingSnapshot) {
        if (!billingSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        double totalBilling = 0;

        for (var doc in billingSnapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;

          double amount = double.tryParse(data['totalAmount'].toString()) ?? 0;

          totalBilling += amount;
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('overheads')
              .doc('pOPjXUpSD6Qj1SfcAgu6')
              .get(),
          builder: (context, overheadSnapshot) {
            if (!overheadSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = overheadSnapshot.data!.data() as Map<String, dynamic>;

            double electricity = (data['electricity'] ?? 0).toDouble();

            double internet = (data['internet'] ?? 0).toDouble();

            double rent = (data['rent'] ?? 0).toDouble();

            double salary = (data['salary'] ?? 0).toDouble();

            double totalOverhead = electricity + internet + rent + salary;

            double profit = totalBilling - totalOverhead;

            return Row(
              children: [
                _card("Total Billing", totalBilling),

                const SizedBox(width: 20),

                _card("Total Overhead", totalOverhead),

                const SizedBox(width: 20),

                _card("Net Profit", profit),
              ],
            );
          },
        );
      },
    );
  }

  Widget _card(String title, double value) {
    return Expanded(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                "₹${value.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
