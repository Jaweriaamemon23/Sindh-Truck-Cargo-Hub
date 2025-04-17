import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:provider/provider.dart';
import 'providers/language_provider.dart';
import 'screens/splash_screen.dart';

final FirebaseMessaging messaging = FirebaseMessaging.instance;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _initializeFirebaseIfNeeded();
  print("🔔 Background message received: ${message.messageId}");
}

Future<void> _initializeFirebaseIfNeeded() async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyB8daSx_lP5pBLUqiD8LsKW2Mer2V9Jy8U",
        authDomain: "sindhtruckcargohub.firebaseapp.com",
        projectId: "sindhtruckcargohub",
        storageBucket: "sindhtruckcargohub.appspot.com",
        messagingSenderId: "22061893159",
        appId: "1:22061893159:web:0802de538103a6e22eb002",
      ),
    );
    print("✅ Firebase initialized successfully");
  } else {
    print("ℹ️ Firebase already initialized.");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initializeFirebaseIfNeeded();

    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    } else {
      print("ℹ️ Web platform detected — service worker handled in index.html.");
    }
  } catch (e) {
    print("❌ Firebase initialization error: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Sindh Truck Cargo Hub',
      home: const SplashScreen(),
    );
  }
}
