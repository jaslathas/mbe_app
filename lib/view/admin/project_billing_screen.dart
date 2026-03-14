import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  String? selectedProjectId;
  String? selectedProjectName;
  String? selectedProjectCode;
  String? selectedClientName;

  bool isLoading = false;

  Map<String, Map<String, dynamic>> employeeData = {};
  double totalAmount = 0;

  // ================= BILL CALCULATION =================
  Future<void> generateBill() async {
    if (selectedProjectId == null) return;

    setState(() {
      isLoading = true;
      employeeData.clear();
      totalAmount = 0;
    });

    try {
      final timesheetSnapshot = await FirebaseFirestore.instance
          .collection('timesheets')
          .where('projectId', isEqualTo: selectedProjectId)
          .get();

      Map<String, double> userHours = {};

      for (var doc in timesheetSnapshot.docs) {
        final data = doc.data();
        final userId = data['userId'];
        final hours = (data['hours'] ?? 0).toDouble();

        if (userId == null) continue;

        userHours[userId] = (userHours[userId] ?? 0) + hours;
      }

      for (var entry in userHours.entries) {
        final userId = entry.key;
        final hours = entry.value;

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        final userData = userDoc.data();
        final userName = userData?['name'] ?? "Unknown";
        final rate = (userData?['hourlyRate'] ?? 0).toDouble();

        final amount = hours * rate;

        totalAmount += amount;

        employeeData[userName] = {
          'hours': hours,
          'rate': rate,
          'amount': amount,
        };
      }
    } catch (e) {
      debugPrint("Billing Error: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  // ================= INVOICE PDF =================
  Future<void> generateInvoicePDF() async {
    final firestore = FirebaseFirestore.instance;
    final logoBytes = await rootBundle.load('assets/logo.jpeg');
    final logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());

    final invoiceNo = await firestore.runTransaction((transaction) async {
      final counterRef = firestore.collection('invoice_counter').doc('billing');

      final snapshot = await transaction.get(counterRef);

      int lastNumber = 0;

      if (!snapshot.exists) {
        transaction.set(counterRef, {'lastInvoiceNumber': 1});
        return "PSV1";
      } else {
        lastNumber = snapshot['lastInvoiceNumber'];
        final newNumber = lastNumber + 1;
        transaction.update(counterRef, {'lastInvoiceNumber': newNumber});
        return "PSV$newNumber";
      }
    });

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ================= HEADER =================
                pw.Padding(
                  padding: const pw.EdgeInsets.all(15),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Image(logoImage, width: 90, height: 80),

                      // LEFT LOGO + NAME

                      // RIGHT INVOICE DETAILS
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "Invoice No: $invoiceNo",
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            "Date: ${DateTime.now().day}/"
                            "${DateTime.now().month}/"
                            "${DateTime.now().year}",
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ================= MAILING SECTION =================
                pw.Container(
                  color: PdfColors.grey300,
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      // LEFT ADDRESS
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Mailing Info :"),
                          pw.Text("Door No: 38/2643/H4"),
                          pw.Text("2nd Floor, Happy Tower"),
                          pw.Text("Meenchanda, Vattakinar"),
                          pw.Text("Calicut - 673018"),
                          pw.Text("Phone - +91 80893 16426"),
                        ],
                      ),

                      // RIGHT BILL TO
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Bill to :"),
                          pw.Text("$selectedClientName"),
                          pw.Text("Calicut"),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 10),

                // ================= PROJECT INFO =================
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Project : $selectedProjectName"),
                      pw.Text("Project code: $selectedProjectCode"),
                    ],
                  ),
                ),

                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                  child: pw.Text("Location: Kannur"),
                ),

                pw.SizedBox(height: 10),

                // ================= FEE NOTE =================
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                  child: pw.Text(
                    "Finalized Total Fee (Excluding GST/other expenses/reimbursable/travelling expenses) is  Rs. ${totalAmount.toStringAsFixed(0)}",
                  ),
                ),

                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                  child: pw.Text(
                    "The advance amount received upon confirmation is  Rs. 0",
                  ),
                ),

                pw.SizedBox(height: 10),

                // ================= TABLE HEADER =================
                pw.Container(
                  color: PdfColors.grey400,
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "ITEM",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        "DESCRIPTION",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        "AMOUNT",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                // ================= SERVICE ROW =================
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Service Fee :"),
                      pw.Text("Upon submission of structural drawing"),
                      pw.Text("₹${totalAmount.toStringAsFixed(0)}"),
                    ],
                  ),
                ),

                pw.Spacer(),

                // ================= BANK + TOTAL SECTION =================
                pw.Container(
                  color: PdfColors.grey300,
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      // BANK DETAILS
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text("Make all checks payable to: JAISAL A K"),
                          pw.Text("Account No: 1111111111111"),
                          pw.Text("Branch : SBI Feroke"),
                          pw.Text("G-pay : 444444444444"),
                        ],
                      ),

                      // TOTAL SECTION
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            "SUBTOTAL: Rs.${totalAmount.toStringAsFixed(0)}",
                          ),
                          pw.Text("TAX/GST: -"),
                          pw.Text("S & H : -"),
                          pw.Text("DISCOUNT : -"),
                        ],
                      ),
                    ],
                  ),
                ),

                // ================= FINAL TOTAL BAR =================
                pw.Container(
                  width: double.infinity,
                  color: PdfColors.grey400,
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "TOTAL :",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        "₹${totalAmount.toStringAsFixed(0)}",
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 50),

                // ================= FOOTER =================
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text("Authorized Signature"),
                      pw.SizedBox(height: 30),
                      pw.Text("JAISAL A K"),
                    ],
                  ),
                ),

                pw.SizedBox(height: 10),

                pw.Center(child: pw.Text("Thank you for your Business !")),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: "Invoice_$selectedProjectCode.pdf",
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Project Billing",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // PROJECT DROPDOWN
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('projects')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final projects = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  initialValue: selectedProjectId,
                  hint: const Text("Select Project"),
                  items: projects.map((doc) {
                    final data = doc.data();

                    return DropdownMenuItem<String>(
                      value: doc.id,
                      child: Text(
                        "${data['projectCode']} - ${data['projectName']}",
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    final selectedDoc = projects.firstWhere(
                      (doc) => doc.id == value,
                    );

                    final data = selectedDoc.data();

                    setState(() {
                      selectedProjectId = value;
                      selectedProjectName = data['projectName'];
                      selectedProjectCode = data['projectCode'];
                      selectedClientName = data['clientName'];
                    });
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: isLoading ? null : generateBill,
              child: const Text("Generate Bill"),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: employeeData.entries.map((entry) {
                  final name = entry.key;
                  final data = entry.value;

                  return Card(
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text(
                        "Hours: ${data['hours']} | Rate: ₹${data['rate']}",
                      ),
                      trailing: Text(
                        "₹${data['amount'].toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            if (employeeData.isNotEmpty)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(15),
                    width: double.infinity,
                    color: Colors.green.shade200,
                    child: Text(
                      "Total: ₹${totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: generateInvoicePDF,
                    child: const Text("Download Invoice PDF"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
