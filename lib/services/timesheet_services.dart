import 'package:cloud_firestore/cloud_firestore.dart';

class TimesheetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addTimesheet({
    required String employeeUid,
    required String projectId,
    required DateTime date,
    required String slot,
    required String description,
    double slotDuration = 0.5,
  }) async {
    final dateString = "${date.year}-${date.month}-${date.day}";

    /// Prevent duplicate slot
    final existing = await _firestore
        .collection('timesheets')
        .where('employeeUid', isEqualTo: employeeUid)
        .where('date', isEqualTo: dateString)
        .where('slot', isEqualTo: slot)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception("Slot already logged");
    }

    await _firestore.collection('timesheets').add({
      'employeeUid': employeeUid,
      'projectId': projectId,
      'date': dateString,
      'slot': slot,
      'slotDuration': slotDuration,
      'description': description,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<double> getDailyTotal(String employeeUid, String date) async {
    final snapshot = await _firestore
        .collection('timesheets')
        .where('employeeUid', isEqualTo: employeeUid)
        .where('date', isEqualTo: date)
        .get();

    double total = 0;

    for (var doc in snapshot.docs) {
      total += (doc['slotDuration'] ?? 0).toDouble();
    }

    return total;
  }
}
