import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _selectedRole = 'employee';
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  ////////////////////////////////////////////////////////////////////////
  /// REGISTER USER
  ////////////////////////////////////////////////////////////////////////
  ///
  ///
  Future<void> _checkAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final role = doc['role'];

    if (role != 'admin') {
      if (mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Access denied")));
      }
    }
  }

  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);

      /// 1️⃣ Create Auth User
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text.trim(),
          );

      String uid = userCredential.user!.uid;

      /// 2️⃣ Generate Employee Code (Only for employee)
      String? employeeCode;
      if (_selectedRole == 'employee') {
        employeeCode = await generateEmployeeId();
      }

      /// 3️⃣ Save User in Firestore
      await _firestore.collection('users').doc(uid).set({
        'name': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'role': _selectedRole,
        'employeeCode': employeeCode,
        'hourlyRate': _selectedRole == 'employee' ? 500 : 0, // default rate
        'createdAt': FieldValue.serverTimestamp(),
      });

      /// 4️⃣ Sign out after registration
      await _auth.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration successful. Please login.")),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Auth Error")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  ////////////////////////////////////////////////////////////////////////
  /// SAFE EMPLOYEE ID GENERATOR (FIXED)
  ////////////////////////////////////////////////////////////////////////

  Future<String> generateEmployeeId() async {
    final counterRef = FirebaseFirestore.instance
        .collection('counters')
        .doc('employees');

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      int lastId = 0;

      if (snapshot.exists) {
        lastId = snapshot.data()?['lastId'] ?? 0;
      }

      int newId = lastId + 1;

      transaction.set(counterRef, {'lastId': newId}, SetOptions(merge: true));

      return "EMP-${newId.toString().padLeft(3, '0')}";
    });
  }

  ////////////////////////////////////////////////////////////////////////
  /// DISPOSE
  ////////////////////////////////////////////////////////////////////////

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  ////////////////////////////////////////////////////////////////////////
  /// UI
  ////////////////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 900;

    return Scaffold(
      appBar: AppBar(title: const Text("Register Account")),
      body: isSmallScreen
          ? _buildFormOnly() // Mobile / small web
          : Row(
              children: [
                Expanded(flex: 5, child: _buildFormOnly()),
                Expanded(
                  flex: 7,
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage("assets/login_image.jpg"),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFormOnly() {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(40),
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.app_registration, size: 70),
                const SizedBox(height: 20),

                const Text(
                  "Create Account",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 30),

                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: "Full Name"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "Enter full name" : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (v) => v == null || !v.contains('@')
                      ? "Enter valid email"
                      : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Password"),
                  validator: (v) =>
                      v == null || v.length < 6 ? "Minimum 6 characters" : null,
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  decoration: const InputDecoration(labelText: "Role"),
                  items: const [
                    DropdownMenuItem(
                      value: 'employee',
                      child: Text("Employee"),
                    ),
                    DropdownMenuItem(value: 'admin', child: Text("Admin")),
                    DropdownMenuItem(
                      value: 'director',
                      child: Text("Director"),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedRole = value!);
                  },
                ),

                const SizedBox(height: 30),

                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _registerUser,
                        child: const Text("REGISTER"),
                      ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text("Already have an account? Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
