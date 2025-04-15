import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; // Ensure that this is imported for the dialog
import 'dart:convert';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/services.dart' show rootBundle;

// 🔧 Initialize Firebase Messaging and setup token
final FirebaseMessaging messaging = FirebaseMessaging.instance;
final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>(); // Declare navigatorKey

/// 🔧 Initialize messaging + store token under phone number in Firestore
Future<void> setupFirebaseMessaging() async {
  print("🔧 Requesting notification permissions...");
  await messaging.requestPermission(alert: true, badge: true, sound: true);
  print("📲 Getting FCM Token...");
  String? token = await messaging.getToken(
    vapidKey: kIsWeb
        ? "BOfCymZjawSYZtT48IaOzuKZEezVASta8yMWUMM9OKI4i9DBwuLWEQmkrUgRzHlviRWTvsTtYdzRCP8fS_HnGAA"
        : null,
  );
  print("✅ FCM Token: $token");

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📩 Foreground message: ${message.notification?.title}');

    if (message.notification != null && !kIsWeb) {
      // Improved dialog display with context check and fallback
      showNotificationDialog(message);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print("📲 Notification clicked: ${message.data}");
    // Handle navigation based on the notification data if needed
    handleNotificationClick(message);
  });

  // Add token refresh handling
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
    print("🔄 Token refreshed: $newToken");
    // Update token in Firestore or elsewhere
    saveTokenWithUserInfo(
        phone: FirebaseAuth.instance.currentUser?.phoneNumber ?? 'Unknown',
        userType: 'Transporter');
  });
}

/// Show notification dialog with fallback
Future<void> showNotificationDialog(RemoteMessage message) async {
  BuildContext? ctx = navigatorKey.currentContext;

  if (ctx == null) {
    await Future.delayed(Duration(milliseconds: 300));
    ctx = navigatorKey.currentContext;
  }

  if (ctx != null) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(message.notification?.title ?? 'Notification'),
        content: Text(message.notification?.body ?? ''),
      ),
    );
  } else {
    print("⚠️ Context still not available for dialog.");
  }
}

/// Handle notification click (navigate based on data)
Future<void> handleNotificationClick(RemoteMessage message) async {
  final routeName = message.data['route'] ?? '';
  if (navigatorKey.currentState != null && routeName.isNotEmpty) {
    navigatorKey.currentState!.pushNamed(routeName);
  }
}

Future<String?> getAccessToken() async {
  try {
    final String serviceAccountJson =
        await rootBundle.loadString("assets/firebase-admin-key.json");

    final Map<String, dynamic> credentials = jsonDecode(serviceAccountJson);
    final accountCredentials =
        auth.ServiceAccountCredentials.fromJson(credentials);

    final client = await auth.clientViaServiceAccount(
      accountCredentials,
      ["https://www.googleapis.com/auth/firebase.messaging"],
    );

    return client.credentials.accessToken.data;
  } catch (e) {
    print("❌ Error getting OAuth token: $e");
    return null;
  }
}

// 🔧 Send FCM notification to all truck owners
Future<void> sendFCMNotificationToTruckOwners({
  required String cargoDetails,
  required String weight,
  required String fromLocation,
  required String toLocation,
  required String distance,
  required String vehicleType,
}) async {
  try {
    final accessToken = await getAccessToken();
    if (accessToken == null) {
      print("❌ Failed to get OAuth token.");
      return;
    }

    // Fetch truck owners' FCM tokens from Firestore
    final truckOwnersSnapshot = await FirebaseFirestore.instance
        .collection('user_fcm_tokens')
        .where('userType', isEqualTo: 'Truck Owner')
        .get();

    if (truckOwnersSnapshot.docs.isEmpty) {
      print("❌ No truck owners found.");
      return;
    }

    // Send notifications to each truck owner
    for (var doc in truckOwnersSnapshot.docs) {
      final token = doc.data()['fcmToken'];
      if (token == null || token.isEmpty) continue;

      final notificationPayload = {
        "message": {
          "token": token,
          "notification": {
            "title": "New Cargo Request! 📦",
            "body":
                "$cargoDetails | $weight kg from $fromLocation to $toLocation",
          },
          "data": {
            "type": "cargo_request",
            "cargoDetails": cargoDetails,
            "weight": weight,
            "sender": fromLocation,
            "to": toLocation,
            "distance": distance,
            "vehicleType": vehicleType,
          },
        }
      };

      final response = await http.post(
        Uri.parse(
            "https://fcm.googleapis.com/v1/projects/sindhtruckcargohub/messages:send"), // Replace your_project_id with your actual project ID
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode(notificationPayload),
      );

      if (response.statusCode == 200) {
        print("✅ Notification sent to: ${doc.id}");
      } else {
        print("❌ Failed for ${doc.id}: ${response.body}");
      }
    }
  } catch (e) {
    print("❌ Error sending truck owner notifications: $e");
  }
}

/// ✅ Store FCM token with user info (handles token updates and multiple devices)
Future<void> saveTokenWithUserInfo({
  required String phone,
  required String userType,
}) async {
  print("🔧 Storing FCM token for user: $phone");

  String? token = await messaging.getToken();

  if (token == null) {
    print("⚠️ No FCM token found to save.");
    return;
  }

  try {
    await FirebaseFirestore.instance
        .collection('user_fcm_tokens')
        .doc(phone)
        .collection('tokens') // Store token in a sub-collection for uniqueness
        .doc(token) // Use token as document ID
        .set({
      'fcmToken': token,
      'userType': userType,
      'timestamp': FieldValue.serverTimestamp(),
      'platform': defaultTargetPlatform.toString(),
    });

    print("✅ FCM token stored in 'user_fcm_tokens/$phone/tokens/$token'");
  } catch (e) {
    print("❌ Failed to save token with user info: $e");
  }
}
