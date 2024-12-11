import 'package:flutter/material.dart';
import 'otp_screen.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? selectedUserType;

  final List<String> userTypes = [
    'Admin',
    'Truck Owner',
    'Cargo Transporter',
    'Business Owner'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      constraints.maxHeight, // Ensure gradient fills the screen
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 50),
                      Text(
                        "Create Your Account",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 30),
                      // Name Field
                      _buildTextField(_nameController, "Name", Icons.person),
                      SizedBox(height: 16),
                      // Email Field
                      _buildTextField(_emailController, "Email", Icons.email),
                      SizedBox(height: 16),
                      // Password Field
                      _buildTextField(
                          _passwordController, "Password", Icons.lock,
                          isPassword: true),
                      SizedBox(height: 16),
                      // Phone Number Field
                      _buildTextField(
                          _phoneController, "Phone Number", Icons.phone),
                      SizedBox(height: 16),
                      // Dropdown Field
                      DropdownButtonFormField<String>(
                        value: selectedUserType,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          labelText: "Select User Type",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: userTypes.map((String userType) {
                          return DropdownMenuItem<String>(
                            value: userType,
                            child: Text(userType),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedUserType = newValue;
                          });
                        },
                      ),
                      SizedBox(height: 20),
                      // Register Button
                      ElevatedButton(
                        onPressed: () {
                          final phoneNumber = _phoneController.text;

                          if (phoneNumber.isNotEmpty &&
                              selectedUserType != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    OtpScreen(phoneNumber: phoneNumber),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Please fill in all fields!')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue.shade900,
                          textStyle: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        child: Text('Register'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
