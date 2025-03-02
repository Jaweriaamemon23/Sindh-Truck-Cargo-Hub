import 'package:flutter/material.dart';
import 'firestore_helper.dart'; // Import Firestore helper functions
import 'login_screen.dart'; // ✅ Import Login Screen

class TruckOwnerForm extends StatefulWidget {
  final String
      userId; // Receive the userId (Phone Number) from the previous screen

  const TruckOwnerForm({required this.userId, Key? key}) : super(key: key);

  @override
  _TruckOwnerFormState createState() => _TruckOwnerFormState();
}

class _TruckOwnerFormState extends State<TruckOwnerForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _driverAgeController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _vehicleNumController = TextEditingController();
  final TextEditingController _licenseNumController = TextEditingController();

  /// **🔥 Submits the form & navigates to Login Screen**
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        // ✅ Collect form data
        Map<String, dynamic> truckOwnerData = {
          'driverAge': int.parse(_driverAgeController.text.trim()),
          'vehicleType': _vehicleTypeController.text.trim(),
          'vehicleNumber': _vehicleNumController.text.trim(),
          'licenseNumber': _licenseNumController.text.trim(),
          'createdAt': DateTime.now(),
        };

        // ✅ Save Truck Owner Data in Firestore (Subcollection inside user's document)
        await FirestoreHelper()
            .createTruckOwnerData(widget.userId, truckOwnerData);

        // ✅ Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Registration successful! Please log in.')),
        );

        // ✅ Navigate to Login Screen (Instead of Dashboard)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🔥 Error saving data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Truck Owner Details"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                      _driverAgeController, "Driver Age", Icons.cake),
                  const SizedBox(height: 16),
                  _buildTextField(_vehicleTypeController, "Vehicle Type",
                      Icons.local_shipping),
                  const SizedBox(height: 16),
                  _buildTextField(_vehicleNumController, "Vehicle Number",
                      Icons.confirmation_number),
                  const SizedBox(height: 16),
                  _buildTextField(
                      _licenseNumController, "License Number", Icons.badge),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "Submit",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}
