import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final FirebaseMessaging messaging = FirebaseMessaging.instance;

const String serverKey =
    'AIzaSyDT5Y3URsZNzYV_rC8OznbXRyuxpAuvwX8'; // 🔐 Keep secret

// 🔐 Store FCM token using phone number as doc ID
Future<void> handleFCMToken(String phoneNumber) async {
  final token = await messaging.getToken();
  if (token != null) {
    print("✅ FCM Token: $token");
    await FirebaseFirestore.instance.collection('users').doc(phoneNumber).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  } else {
    print("❌ Could not get FCM token.");
  }
}

// 📬 Subscribe to a topic
void subscribeToTopic(String topic) {
  messaging.subscribeToTopic(topic);
  print("📌 Subscribed to topic: $topic");
}

// 🚚 Send cargo notification with full request data
Future<void> sendNotificationToTruckOwners({
  required String transporterPhone,
  required String transporterName,
  required String transporterEmail,
  required String cargoDetails,
  required String weight,
  required String fromLocation,
  required String toLocation,
  required String distance,
  required String vehicleType,
}) async {
  try {
    final cargoRequestData = {
      'transporterPhone': transporterPhone,
      'transporterName': transporterName,
      'transporterEmail': transporterEmail,
      'cargoDetails': cargoDetails,
      'weight': weight,
      'fromLocation': fromLocation,
      'toLocation': toLocation,
      'distance': distance,
      'vehicleType': vehicleType,
      'timestamp': FieldValue.serverTimestamp(),
    };

    // Save the request first
    final requestRef = await FirebaseFirestore.instance
        .collection('cargo_requests')
        .add(cargoRequestData);

    print("📦 Cargo request saved with ID: ${requestRef.id}");

    // Now notify truck owners
    final userDocs = await FirebaseFirestore.instance.collection('users').get();

    for (var doc in userDocs.docs) {
      final data = doc.data();
      final userType = data['userType'];
      final fcmToken = data['fcmToken'];

      if (userType == 'Truck Owner' &&
          fcmToken != null &&
          fcmToken.toString().isNotEmpty) {
        await sendFCMNotification(
          token: fcmToken,
          title: 'New Cargo Request',
          body:
              '$transporterName needs cargo from $fromLocation to $toLocation',
        );

        await storeNotificationInFirestore(
          toUserId: doc.id,
          fromUserId: transporterPhone,
          fromUserName: transporterName,
          relatedRequestId: requestRef.id,
          cargoDetails: cargoDetails,
          weight: weight,
          fromLocation: fromLocation,
          toLocation: toLocation,
          distance: distance,
          vehicleType: vehicleType,
        );
      }
    }

    print("✅ All notifications sent.");
  } catch (e) {
    print("🚨 Error sending notifications: $e");
  }
}

// 🔥 Send raw FCM push
Future<void> sendFCMNotification({
  required String token,
  required String title,
  required String body,
}) async {
  try {
    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode({
        'to': token,
        'notification': {
          'title': title,
          'body': body,
        },
        'priority': 'high',
      }),
    );

    if (response.statusCode == 200) {
      print("📲 Notification sent.");
    } else {
      print("❌ Failed to send: ${response.body}");
    }
  } catch (e) {
    print("❌ FCM error: $e");
  }
}

// 💾 Store notification metadata
Future<void> storeNotificationInFirestore({
  required String toUserId,
  required String fromUserId,
  required String fromUserName,
  required String relatedRequestId,
  required String cargoDetails,
  required String weight,
  required String fromLocation,
  required String toLocation,
  required String distance,
  required String vehicleType,
}) async {
  await FirebaseFirestore.instance.collection('notifications').add({
    'toUserId': toUserId,
    'fromUserId': fromUserId,
    'fromUserName': fromUserName,
    'cargoDetails': cargoDetails,
    'weight': weight,
    'fromLocation': fromLocation,
    'toLocation': toLocation,
    'distance': distance,
    'vehicleType': vehicleType,
    'relatedRequestId': relatedRequestId,
    'timestamp': FieldValue.serverTimestamp(),
  });
}
