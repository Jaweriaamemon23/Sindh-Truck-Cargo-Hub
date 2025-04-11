import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/splash_screen.dart';

final FirebaseMessaging messaging = FirebaseMessaging.instance;
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

    if (kIsWeb) {
      print("ℹ️ Skipping service worker setup in Dart. Handled in index.html.");
    }
  } catch (e) {
    print("❌ Firebase initialization error: $e");
  }

  setupFirebaseMessaging();

  runApp(const MyApp());
}

void setupFirebaseMessaging() {
  if (!kIsWeb) {
    messaging.subscribeToTopic('cargo_available');
  }

  FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  messaging
      .getToken(
          vapidKey: kIsWeb
              ? "BOfCymZjawSYZtT48IaOzuKZEezVASta8yMWUMM9OKI4i9DBwuLWEQmkrUgRzHlviRWTvsTtYdzRCP8fS_HnGAA"
              : null)
      .then((token) {
    print("FCM Token: $token");
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📩 Foreground message: ${message.notification?.title}');
    if (message.notification != null && !kIsWeb) {
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (context) => AlertDialog(
          title: Text(message.notification!.title ?? 'No Title'),
          content: Text(message.notification!.body ?? 'No Body'),
        ),
      );
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: SplashScreen(),
      ),
    );
  }
}
