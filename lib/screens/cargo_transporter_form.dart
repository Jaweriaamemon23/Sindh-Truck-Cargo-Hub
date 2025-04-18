import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'login_screen.dart';
import '../providers/language_provider.dart';

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

        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'userId': userId,
          'name': widget.userData['name'],
          'email': widget.userData['email'],
          'phone': widget.userData['phone'],
          'userType': "Cargo Transporter",
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        DocumentReference cargoRef = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('cargoTransporter')
            .doc("details");

        await cargoRef.set({
          'companyName': _companyNameController.text.trim(),
          'companyType': _companyTypeController.text.trim(),
          'isCompanyVerified': _isCompanyVerified,
          'timestamp': FieldValue.serverTimestamp(),
        });

        DocumentSnapshot snapshot = await cargoRef.get();
        if (snapshot.exists) {
          print(
              "[CONFIRMED] Firestore successfully saved the subcollection data!");
        } else {
          print("[ERROR] Firestore DID NOT save the subcollection data! 🚨");
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  Provider.of<LanguageProvider>(context, listen: false).isSindhi
                      ? 'ڪاميابي سان رجسٽر ٿيو! مهرباني ڪري لاگ ان ٿيو.'
                      : 'Registered successfully! Please log in.')),
        );

        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => LoginScreen()));
      } catch (e) {
        print("❌ Firestore error: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                Provider.of<LanguageProvider>(context, listen: false).isSindhi
                    ? 'ڊيٽا محفوظ ڪرڻ ۾ نقص: $e'
                    : 'Error saving data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSindhi = Provider.of<LanguageProvider>(context).isSindhi;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSindhi
            ? "ڪارگو ٽرانسپورٽر تفصيلات"
            : "Cargo Transporter Details"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              Provider.of<LanguageProvider>(context, listen: false)
                  .toggleLanguage();
            },
          ),
        ],
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
                    _companyNameController,
                    isSindhi ? "ڪمپني جو نالو" : "Company Name",
                    Icons.business,
                    isSindhi,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    _companyTypeController,
                    isSindhi ? "ڪمپني جو قسم" : "Company Type",
                    Icons.business_center,
                    isSindhi,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(isSindhi
                        ? "ڇا ڪمپني تصديق ٿيل آهي؟"
                        : "Is Company Verified?"),
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
                    child: Text(
                      isSindhi ? "رجسٽر ٿيو" : "Register",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
    TextEditingController controller,
    String label,
    IconData icon,
    bool isSindhi,
  ) {
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
          return isSindhi
              ? 'مھرباني ڪري $label داخل ڪريو'
              : 'Please enter $label';
        }
        return null;
      },
    );
  }
}
