import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore firestore = FirebaseFirestore.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyB8daSx_lP5pBLUqiD8LsKW2Mer2V9Jy8U",
        authDomain: "sindhtruckcargohub.firebaseapp.com",
        projectId: "sindhtruckcargohub",
        storageBucket: "sindhtruckcargohub.appspot.com", // Fixed this
        messagingSenderId: "22061893159",
        appId: "1:22061893159:web:0802de538103a6e22eb002",
      ),
    );
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase initialization error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
