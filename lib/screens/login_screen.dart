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
import 'admin_dashboard.dart';

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
    final isSindhi =
        Provider.of<LanguageProvider>(context, listen: false).isSindhi;

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isSindhi
                ? 'مهرباني ڪري اي ميل ۽ پاسورڊ داخل ڪريو.'
                : 'Please enter email and password.')),
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
          SnackBar(
              content: Text(isSindhi
                  ? 'اوچتو نقص پيش آيو.'
                  : "Unexpected error occurred.")),
        );
        setState(() => _isLoading = false);
        return;
      }

      await user.reload();
      user = _auth.currentUser;

      final isAdmin = user!.email == 'sindhtruckcargohub@gmail.com';

      if (!isAdmin && !user.emailVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isSindhi
                  ? 'مهرباني ڪري لاگ ان کان پهريان اي ميل جي تصديق ڪريو.'
                  : 'Please verify your email before logging in.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where('email', isEqualTo: user.email!)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  isSindhi ? 'صارف جو ڊيٽا نه مليو.' : "User data not found.")),
        );
        setState(() => _isLoading = false);
        return;
      }

      DocumentSnapshot userDoc = userQuery.docs.first;

      final userData = userDoc.data() as Map<String, dynamic>?;

      if (userData == null) {
        print("DEBUG: userData is null for document ID: ${userDoc.id}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isSindhi
                  ? 'صارف جو ڊيٽا ملي نه سگهيو.'
                  : 'User data could not be loaded.')),
        );
        await _auth.signOut();
        setState(() => _isLoading = false);
        return;
      }

      print("DEBUG: userData = $userData");

      final verifiedField = userData['verified'];
      print(
          "DEBUG: verified field = $verifiedField, type = ${verifiedField.runtimeType}");

      if (!isAdmin && (verifiedField != true)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(isSindhi
                  ? 'توهان جو اڪائونٽ اڃا منظوري هيٺ آهي.'
                  : 'Your account is pending admin approval.')),
        );
        await _auth.signOut();
        setState(() => _isLoading = false);
        return;
      }

      await _saveEmailToRecent(user.email!);

      if (isAdmin) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => AdminDashboard()));
        return;
      }

      await _firestore.collection('users').doc(user.email).update({
        'emailVerified': true,
      }).catchError((_) {});

      await setupFirebaseMessaging();

      String userType = userData['userType'];
      String phone = userData['phone'];

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
            SnackBar(
                content:
                    Text(isSindhi ? 'اڻڄاتل صارف قسم.' : "Unknown user type.")),
          );
          setState(() => _isLoading = false);
          return;
      }

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => dashboard));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isSindhi
                ? "لاگ ان ناڪام: ${e.message}"
                : "Login failed: ${e.message}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                isSindhi ? 'اوچتو نقص پيش آيو: $e' : "Unexpected error: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _resetPassword(String email) async {
    final isSindhi =
        Provider.of<LanguageProvider>(context, listen: false).isSindhi;

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSindhi
              ? 'مهرباني ڪري پنهنجو اي ميل داخل ڪريو'
              : 'Please enter your email address'),
        ),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isSindhi
              ? 'پاسورڊ ري سيٽ لنڪ توهان جي اي ميل تي موڪليو ويو آهي'
              : 'Password reset link has been sent to your email'),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = isSindhi
              ? 'هن اي ميل سان ڪوبه اڪائونٽ نه مليو'
              : 'No account found with this email';
          break;
        case 'invalid-email':
          errorMessage =
              isSindhi ? 'غلط اي ميل فارميٽ' : 'Invalid email format';
          break;
        default:
          errorMessage = isSindhi
              ? 'پاسورڊ ري سيٽ ناڪام: ${e.message}'
              : 'Password reset failed: ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              isSindhi ? 'اوچتو نقص پيش آيو' : 'An unexpected error occurred'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isSindhi = langProvider.isSindhi;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade50,
                  Colors.blue.shade100,
                  Colors.blue.shade200
                ],
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
                        SizedBox(height: 60),
                        Text(
                          isSindhi ? "!ڀلي ڪري آيا" : "Welcome Back!",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
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
                        SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              _resetPassword(_emailController.text);
                            },
                            child: Text(
                              isSindhi
                                  ? "پاسورڊ وساري ويٺو آهيو؟"
                                  : "Forgot Password?",
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 30),
                        _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                    color: Colors.blue.shade700))
                            : ElevatedButton(
                                onPressed: _handleLogin,
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  shadowColor: Colors.blue.shade300,
                                  elevation: 8,
                                ),
                                child: Text(
                                  isSindhi ? 'لاگ ان ڪريو' : 'Login',
                                  style: TextStyle(fontSize: 18),
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
                            style: TextStyle(
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 30,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.language, color: Colors.blue.shade900),
              tooltip: isSindhi ? 'انگريزي ۾ ڪريو' : 'Switch to Sindhi',
              onPressed: () {
                langProvider.toggleLanguage();
              },
            ),
          ),
        ],
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
            .where(
                (email) => email.toLowerCase().contains(pattern.toLowerCase()))
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
