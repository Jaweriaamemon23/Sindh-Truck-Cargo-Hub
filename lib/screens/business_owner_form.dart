import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BusinessOwnerForm extends StatefulWidget {
  final String name;
  final String email;
  final String phone;

  BusinessOwnerForm(
      {required this.name, required this.email, required this.phone});

  @override
  _BusinessOwnerFormState createState() => _BusinessOwnerFormState();
}

class _BusinessOwnerFormState extends State<BusinessOwnerForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _businessTypeController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  void _saveBusinessOwnerData() async {
    if (_formKey.currentState!.validate()) {
      String businessName = _businessNameController.text.trim();
      String businessType = _businessTypeController.text.trim();
      String location = _locationController.text.trim();

      try {
        // Reference to Firestore
        FirebaseFirestore firestore = FirebaseFirestore.instance;

        // Store main user data
        DocumentReference userRef =
            firestore.collection('users').doc(widget.phone);
        await userRef.set({
          'name': widget.name,
          'email': widget.email,
          'phone': widget.phone,
          'userType': 'Business Owner',
        });

        // Store business owner-specific data in subcollection
        await userRef.collection('business_owner').doc('details').set({
          'businessName': businessName,
          'businessType': businessType,
          'location': location,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Business owner data saved successfully!')),
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
          title: Text("Business Owner Details"),
          backgroundColor: Colors.blueAccent),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(
                  _businessNameController, "Business Name", Icons.business),
              _buildTextField(
                  _businessTypeController, "Business Type", Icons.category),
              _buildTextField(
                  _locationController, "Location", Icons.location_on),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveBusinessOwnerData,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent),
                child: Text("Submit",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
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
