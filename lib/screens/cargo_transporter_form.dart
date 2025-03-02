import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class CargoTransporterForm extends StatefulWidget {
  final Map<String, String> userData;

  const CargoTransporterForm({required this.userData, Key? key})
      : super(key: key);

  @override
  _CargoTransporterFormState createState() => _CargoTransporterFormState();
}

class _CargoTransporterFormState extends State<CargoTransporterForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _companyTypeController = TextEditingController();
  bool _isCompanyVerified = false;

  @override
  void initState() {
    super.initState();
    print("✅ User Data received in CargoTransporterForm: ${widget.userData}");
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        String? userId = widget.userData['phone'];
        if (userId == null || userId.isEmpty) {
          throw Exception("❌ User ID (phone) is missing!");
        }

        print("[DEBUG] User ID: $userId");
        print("[DEBUG] Saving main user data...");

        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'userId': userId,
          'name': widget.userData['name'],
          'email': widget.userData['email'],
          'phone': widget.userData['phone'],
          'userType': "Cargo Transporter",
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print("[SUCCESS] Main user data saved!");

        // Create subcollection for Cargo Transporter details
        DocumentReference cargoRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('cargoTransporter') // Subcollection
            .doc("details"); // Document inside subcollection

        print(
            "[DEBUG] Creating Cargo Transporter subcollection at: users/$userId/cargoTransporter/details");

        await cargoRef.set({
          'companyName': _companyNameController.text.trim(),
          'companyType': _companyTypeController.text.trim(),
          'isCompanyVerified': _isCompanyVerified,
          'timestamp': FieldValue.serverTimestamp(),
        });

        print("[SUCCESS] Cargo Transporter details stored in subcollection!");

        // ✅ Check if the data actually exists after writing
        DocumentSnapshot snapshot = await cargoRef.get();
        if (snapshot.exists) {
          print(
              "[CONFIRMED] Firestore successfully saved the subcollection data!");
        } else {
          print("[ERROR] Firestore DID NOT save the subcollection data! 🚨");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registered successfully! Please log in.')),
        );

        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => LoginScreen()));
      } catch (e) {
        print("❌ Firestore error: $e");
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error saving data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Cargo Transporter Details"),
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
                      _companyNameController, "Company Name", Icons.business),
                  const SizedBox(height: 16),
                  _buildTextField(_companyTypeController, "Company Type",
                      Icons.business_center),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text("Is Company Verified?"),
                    value: _isCompanyVerified,
                    onChanged: (value) =>
                        setState(() => _isCompanyVerified = value),
                  ),
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
                      "Register",
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
