import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/splash_screen.dart';

// Initialize Firebase Cloud Messaging
FirebaseMessaging messaging = FirebaseMessaging.instance;

// Create a GlobalKey for navigator to handle the context when app is in background
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyB8daSx_lP5pBLUqiD8LsKW2Mer2V9Jy8U",
        authDomain: "sindhtruckcargohub.firebaseapp.com",
        projectId: "sindhtruckcargohub",
        storageBucket: "sindhtruckcargohub.appspot.com",
        messagingSenderId: "22061893159",
        appId: "1:22061893159:web:0802de538103a6e22eb002",
      ),
    );
    print("✅ Firebase initialized successfully");
  } catch (e) {
    print("❌ Firebase initialization error: $e");
  }

  // Set up Firebase Messaging
  setupFirebaseMessaging();

  runApp(const MyApp());
}

// Firebase Messaging setup
void setupFirebaseMessaging() {
  // Background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Request permission for notifications
  messaging.requestPermission();

  // Get the FCM token
  messaging.getToken().then((token) {
    print("FCM Token: $token");
    // Optionally, save this token in Firestore or use it to send notifications
  });

  // Handle messages when the app is in the foreground
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Received a foreground message: ${message.notification?.title}');

    // Show notification or update UI when message is received
    if (message.notification != null) {
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (context) => AlertDialog(
          title: Text(message.notification!.title!),
          content: Text(message.notification!.body!),
        ),
      );
    }
  });

  // Subscribe to a topic for receiving notifications
  messaging.subscribeToTopic('cargo_available');
}

// Handle background message
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  // Handle background notifications or perform tasks
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // Add the navigator key here
    );
  }
}
