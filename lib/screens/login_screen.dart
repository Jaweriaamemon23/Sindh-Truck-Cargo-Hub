import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/language_provider.dart';
import 'registration_screen.dart';
import 'truck_owner_dashboard.dart';
import 'cargo_transporter_dashboard.dart';
import 'business_owner_dashboard.dart';
import 'firebase_notification_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _isLoading = false;
  List<String> recentEmails = [];

  @override
  void initState() {
    super.initState();
    _loadRecentEmails();
  }

  Future<void> _loadRecentEmails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentEmails = prefs.getStringList('recent_emails') ?? [];
    });
  }

  Future<void> _saveEmailToRecent(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (!recentEmails.contains(email)) {
      recentEmails.insert(0, email);
      if (recentEmails.length > 5) {
        recentEmails = recentEmails.sublist(0, 5);
      }
      await prefs.setStringList('recent_emails', recentEmails);
    }
  }

  Future<void> _handleLogin() async {
    final isSindhi = Provider.of<LanguageProvider>(context, listen: false).isSindhi;

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isSindhi ? 'مهرباني ڪري اي ميل ۽ پاسورڊ داخل ڪريو.' : 'Please enter email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isSindhi ? 'اوچتو نقص پيش آيو.' : "Unexpected error occurred.")),
        );
        return;
      }

      await user.reload();
      user = _auth.currentUser;

      if (!user!.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isSindhi ? 'مهرباني ڪري لاگ ان کان پهريان اي ميل جي تصديق ڪريو.' : 'Please verify your email before logging in.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      if (user.email != null) {
        final email = user.email!;
        await _saveEmailToRecent(email);

        await _firestore.collection('users').doc(email).update({
          'emailVerified': true,
        }).catchError((error) {});
      }

      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: user.email!)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isSindhi ? 'صارف جو ڊيٽا نه مليو.' : "User data not found.")),
        );
        setState(() => _isLoading = false);
        return;
      }

      await setupFirebaseMessaging();

      DocumentSnapshot userDoc = userQuery.docs.first;
      String userType = userDoc['userType'];
      String phone = userDoc['phone'];

      await saveTokenWithUserInfo(phone: phone, userType: userType);

      Widget dashboard;
      switch (userType) {
        case 'Truck Owner':
          dashboard = TruckOwnerDashboard();
          break;
        case 'Cargo Transporter':
          dashboard = CargoTransporterDashboard();
          break;
        case 'Business Owner':
          dashboard = BusinessOwnerDashboard();
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isSindhi ? 'اڻڄاتل صارف قسم.' : "Unknown user type.")),
          );
          setState(() => _isLoading = false);
          return;
      }

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => dashboard));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isSindhi ? "لاگ ان ناڪام: ${e.message}" : "Login failed: ${e.message}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isSindhi ? 'اوچتو نقص پيش آيو: $e' : "Unexpected error: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isSindhi = langProvider.isSindhi;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSindhi ? "لاگ ان اسڪرين" : "Login Screen"),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            tooltip: isSindhi ? 'انگريزي ۾ ڪريو' : 'Switch to Sindhi',
            onPressed: () {
              langProvider.toggleLanguage();
            },
          ),
        ],
      ),
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
                      isSindhi ? "!ڀلي ڪري آيا" : "Welcome Back!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(height: 30),
                    _buildEmailField(isSindhi),
                    SizedBox(height: 16),
                    _buildTextField(
                      _passwordController,
                      isSindhi ? "پاسورڊ" : "Password",
                      Icons.lock,
                      TextInputType.text,
                      obscureText: true,
                    ),
                    SizedBox(height: 30),
                    _isLoading
                        ? Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isSindhi ? 'لاگ ان ڪريو' : 'Login',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                    SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegistrationScreen(),
                          ),
                        );
                      },
                      child: Text(
                        isSindhi
                            ? "اکائونٽ ناهي؟ هتي رجسٽر ٿيو"
                            : "Don't have an account? Register here",
                        style: TextStyle(color: Colors.white),
                      ),
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

  Widget _buildEmailField(bool isSindhi) {
    return TypeAheadFormField<String>(
      textFieldConfiguration: TextFieldConfiguration(
        controller: _emailController,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white,
          labelText: isSindhi ? "اي ميل" : "Email",
          prefixIcon: Icon(Icons.email, color: Colors.deepPurple),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        keyboardType: TextInputType.emailAddress,
      ),
      suggestionsCallback: (pattern) {
        return recentEmails
            .where((email) => email.toLowerCase().contains(pattern.toLowerCase()))
            .toList();
      },
      itemBuilder: (context, String suggestion) {
        return ListTile(
          leading: Icon(Icons.email, color: Colors.deepPurple),
          title: Text(suggestion),
        );
      },
      onSuggestionSelected: (String suggestion) {
        _emailController.text = suggestion;
      },
      hideOnEmpty: true,
      hideOnLoading: true,
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
          borderSide: BorderSide.none,
        ),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
    );
  }
}
