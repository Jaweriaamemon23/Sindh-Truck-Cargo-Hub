import 'package:flutter/material.dart';

// Import the respective dashboard files
import 'admin_dashboard.dart';
import 'truck_owner_dashboard.dart';
import 'cargo_transporter_dashboard.dart';
import 'business_owner_dashboard.dart';
import 'registration_screen.dart'; // Import the Registration Screen

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Hide the debug banner
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Variable to store selected user type (if needed)
  String? selectedUserType;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App Title
                Text(
                  "Welcome Back!",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),

                // User Type Selection (Buttons for User Types)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildUserTypeButton(
                      "Cargo Transporter",
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  CargoTransporterDashboard())),
                    ),
                    _buildUserTypeButton(
                      "Truck Owner",
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TruckOwnerDashboard())),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildUserTypeButton(
                      "Business Owner",
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => BusinessOwnerDashboard())),
                    ),
                    _buildUserTypeButton(
                      "Admin",
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AdminDashboard())),
                    ),
                  ],
                ),
                SizedBox(height: 40),

                // Email Field
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 20),

                // Password Field
                _buildTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock,
                  obscureText: true,
                ),
                SizedBox(height: 20),

                // Login Button
                _buildElevatedButton(
                  "Login",
                  () {
                    // Handle the login process (you can add login logic here)
                    print(
                        'Email: ${_emailController.text}, Password: ${_passwordController.text}');
                  },
                ),

                // Link to navigate to the Registration Screen
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RegistrationScreen()),
                    );
                  },
                  child: Text(
                    'Don\'t have an account? Register here',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Method to build the user type buttons
  Widget _buildUserTypeButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, // Changed to backgroundColor
        foregroundColor: Colors.blue.shade900, // Changed to foregroundColor
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      onPressed: onPressed,
      child: Text(label, style: TextStyle(fontSize: 14)),
    );
  }

  // Method to build text fields (email and password)
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
    );
  }

  // Method to build Elevated Buttons
  Widget _buildElevatedButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade900, // Changed to backgroundColor
        foregroundColor: Colors.white, // Changed to foregroundColor
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      onPressed: onPressed,
      child: Text(label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
