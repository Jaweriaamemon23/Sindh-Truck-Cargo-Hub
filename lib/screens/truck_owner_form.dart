import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'truck_owner_image_upload.dart';

class TruckOwnerForm extends StatefulWidget {
  final String userId;

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
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Collect Truck Owner Data
        Map<String, dynamic> truckOwnerData = {
          'driverAge': int.parse(_driverAgeController.text.trim()),
          'vehicleType': _vehicleTypeController.text.trim(),
          'vehicleNumber': _vehicleNumController.text.trim(),
          'licenseNumber': _licenseNumController.text.trim(),
          'createdAt': DateTime.now(),
          'isCompleted': false, // Mark as incomplete
        };

        // Reference to the user's subcollection
        CollectionReference truckOwnersRef = FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('truckOwners');

        // Add data to the subcollection (temporary data with isCompleted: false)
        DocumentReference truckOwnerRef =
            await truckOwnersRef.add(truckOwnerData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Please upload images to complete registration.')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TruckOwnerImageUpload(
              userId: widget.userId,
              formData: truckOwnerData,
              truckOwnerDocId: truckOwnerRef.id,
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
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
                      "Next",
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
