import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'registration_screen.dart';
import 'truck_owner_dashboard.dart';
import 'cargo_transporter_dashboard.dart';
import 'business_owner_dashboard.dart';
import 'firebase_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  final FirebaseMessaging messaging = FirebaseMessaging.instance;
  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      print("🔄 Attempting login...");
      // 🔑 Authenticate user
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      print("✅ User logged in: ${user?.uid}");

      if (user == null) {
        print("❌ ERROR: FirebaseAuth returned null user.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Unexpected error occurred.")),
        );
        return;
      }
      // 🔄 Force refresh user data
      await user.reload();
      user = _auth.currentUser; // Get updated user data

      // ✅ Check email verification
      if (!user!.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Please verify your email before logging in.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      print("✅ Email verified!");

      // ✅ Update Firestore to reflect email verification
      if (user.email != null) {
        await _firestore.collection('users').doc(user.email).update({
          'emailVerified':
              true, // 🔥 Fix: Update Firestore email verification status
        }).catchError((error) {
          print("❌ Firestore update failed: $error");
        });
      }

      // ✅ Fetch user phone from Firestore using email
      if (user.email == null) {
        print("❌ ERROR: User email is NULL in FirebaseAuth!");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Error: Your email is missing from your account.")),
        );
        setState(() => _isLoading = false);
        return;
      }

      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: user.email!)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        print("❌ ERROR: No user found in Firestore for email: ${user.email}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User data not found.")),
        );
        setState(() => _isLoading = false);
        return;
      }
      await setupFirebaseMessaging();

      DocumentSnapshot userDoc = userQuery.docs.first;
      String userType = userDoc['userType'];
      String phone = userDoc['phone'];

      print("📌 UserType: $userType, Phone: $phone");
      await saveTokenWithUserInfo(phone: phone, userType: userType);
      // 🚀 Navigate to the respective dashboard
      if (userType == 'Truck Owner') {
        // 🚀 Navigate to Truck Owner Dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TruckOwnerDashboard()),
        );
      } else if (userType == 'Cargo Transporter') {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => CargoTransporterDashboard()));
      } else if (userType == 'Business Owner') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => BusinessOwnerDashboard()));
      }
    } on FirebaseAuthException catch (e) {
      print("❌ FirebaseAuthException: ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: ${e.message}")),
      );
    } catch (e) {
      print("❌ Unexpected error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An unexpected error occurred.")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login"), backgroundColor: Colors.blueAccent),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade50, Colors.blueAccent.shade200],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: AutofillGroup(
              child: Form(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Welcome Back!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent),
                    ),
                    SizedBox(height: 30),
                    _buildTextField(_emailController, "Email", Icons.email,
                        TextInputType.emailAddress),
                    SizedBox(height: 16),
                    _buildTextField(_passwordController, "Password", Icons.lock,
                        TextInputType.text,
                        obscureText: true),
                    SizedBox(height: 30),
                    _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Login',
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white)),
                          ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => RegistrationScreen()));
                      },
                      child: Text("Don't have an account? Register here",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, TextInputType keyboardType,
      {bool obscureText = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
    );
  }
}
