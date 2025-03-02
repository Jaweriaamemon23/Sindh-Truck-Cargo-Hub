import 'dart:convert';
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
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? selectedUserType;
  final List<String> userTypes = [
    'Truck Owner',
    'Cargo Transporter',
    'Business Owner'
  ];
  bool _isLoading = false;

  // ✅ Function to hash the password using SHA-256
  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  void _registerUser() async {
    if (!_formKey.currentState!.validate() || selectedUserType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please fill all fields and select a user type!')),
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
          'userId': phone, // ✅ Using phone as document ID
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': phone,
          'userType': selectedUserType,
          'password': hashedPassword, // ✅ Store hashed password
          'emailVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification email sent! Please verify.")),
        );

        _navigateToUserForm(phone); // ✅ Pass phone instead of UID
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Registration failed: $e")));
    }

    setState(() => _isLoading = false);
  }

  void _navigateToUserForm(String phone) {
    Map<String, String> userData = {
      'userId': phone, // ✅ Use phone instead of UID
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': phone,
      'userType': selectedUserType!,
    };
    Widget nextScreen;
    if (selectedUserType == "Cargo Transporter") {
      nextScreen = CargoTransporterForm(userData: userData);
    } else if (selectedUserType == "Truck Owner") {
      nextScreen =
          TruckOwnerForm(userId: phone); // ✅ Use phone instead of userId
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
              _buildTextField(_passwordController, "Password", Icons.lock,
                  obscureText: true),
              _buildTextField(_phoneController, "Phone Number", Icons.phone,
                  keyboardType: TextInputType.phone),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedUserType,
                decoration: InputDecoration(
                  labelText: "Select User Type",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: userTypes
                    .map((userType) => DropdownMenuItem(
                        value: userType, child: Text(userType)))
                    .toList(),
                onChanged: (value) => setState(() => selectedUserType = value),
              ),
              SizedBox(height: 30),
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _registerUser,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent),
                      child: Text("Next",
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
      bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) => value == null || value.trim().isEmpty
            ? 'Please enter $label'
            : null,
      ),
    );
  }
}
