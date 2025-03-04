import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cargo_transporter_form.dart';
import 'truck_owner_form.dart';
import 'business_owner_form.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nicController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? selectedUserType;
  final List<String> userTypes = [
    'Truck Owner',
    'Cargo Transporter',
    'Business Owner'
  ];
  bool _isLoading = false;
  bool _waitingForVerification = false;
  late Timer _emailCheckTimer;

  // ✅ Function to hash the password using SHA-256
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  void _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Please fill all fields correctly!')),
      );
      return;
    }

    if (selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Please select a user type!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String phone = _phoneController.text.trim();
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        await user.sendEmailVerification();
        String hashedPassword = _hashPassword(_passwordController.text.trim());

        // ✅ Store user details in Firestore using PHONE as the user ID
        await _firestore.collection('users').doc(phone).set({
          'userId': phone,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'nic': _nicController.text.trim(),
          'phone': phone,
          'userType': selectedUserType,
          'password': hashedPassword,
          'emailVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Verification email sent! Please verify.")),
        );

        setState(() {
          _isLoading = false;
          _waitingForVerification = true;
        });

        _checkEmailVerification(phone);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Registration failed: $e")),
      );
      setState(() => _isLoading = false);
    }
  }

  void _checkEmailVerification(String phone) {
    _emailCheckTimer = Timer.periodic(Duration(seconds: 3), (timer) async {
      User? user = _auth.currentUser;
      await user?.reload();
      user = _auth.currentUser;

      if (user != null && user.emailVerified) {
        timer.cancel();
        await _firestore.collection('users').doc(phone).update({
          'emailVerified': true,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Email verified! Redirecting...")),
        );

        _navigateToUserForm(phone);
      }
    });
  }

  void _navigateToUserForm(String phone) {
    Map<String, String> userData = {
      'userId': phone,
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'nic': _nicController.text.trim(),
      'phone': phone,
      'userType': selectedUserType!,
    };

    Widget nextScreen;
    if (selectedUserType == "Cargo Transporter") {
      nextScreen = CargoTransporterForm(userData: userData);
    } else if (selectedUserType == "Truck Owner") {
      nextScreen = TruckOwnerForm(userId: phone);
    } else {
      nextScreen = BusinessOwnerForm(
        name: userData['name']!,
        email: userData['email']!,
        phone: userData['phone']!,
      );
    }

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => nextScreen));
  }

  @override
  Widget build(BuildContext context) {
    if (_waitingForVerification) {
      return Scaffold(
        appBar: AppBar(
            title: Text("Email Verification Required"),
            backgroundColor: Colors.blueAccent),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email, size: 80, color: Colors.blueAccent),
              SizedBox(height: 20),
              Text(
                "Please verify your email to continue",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                "A verification link has been sent to your email.",
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
          title: Text("Register Your Account"),
          backgroundColor: Colors.blueAccent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_nameController, "Name", Icons.person),
              _buildTextField(_emailController, "Email", Icons.email,
                  keyboardType: TextInputType.emailAddress),
              _buildTextField(_nicController, "NIC Number", Icons.credit_card,
                  keyboardType: TextInputType.number, nicValidation: true),
              _buildTextField(_passwordController, "Password", Icons.lock,
                  obscureText: true),
              _buildTextField(_phoneController, "Phone Number", Icons.phone,
                  keyboardType: TextInputType.phone, phoneValidation: true),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedUserType,
                decoration: InputDecoration(
                    labelText: "Select User Type",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
                items: userTypes
                    .map((userType) => DropdownMenuItem(
                        value: userType, child: Text(userType)))
                    .toList(),
                onChanged: (value) => setState(() => selectedUserType = value),
                validator: (value) =>
                    value == null ? '❌ Please select a user type' : null,
              ),
              SizedBox(height: 30),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _registerUser,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent),
                      child: Text("Register",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text,
      bool obscureText = false,
      bool nicValidation = false,
      bool phoneValidation = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        validator: (value) {
          if (value == null || value.trim().isEmpty)
            return '❌ Please enter $label';
          if (nicValidation && value.length != 13)
            return '❌ NIC must be exactly 13 digits';
          if (phoneValidation && value.length != 11)
            return '❌ Phone must be exactly 11 digits';
          return null;
        },
      ),
    );
  }
}
