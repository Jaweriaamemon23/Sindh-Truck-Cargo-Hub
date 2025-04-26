import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

final User? currentUser = FirebaseAuth.instance.currentUser;

Future<void> markAsDelivered(String bookingId, BuildContext context) async {
  if (currentUser == null) return;
  final isSindhi =
      Provider.of<LanguageProvider>(context, listen: false).isSindhi;
  final bookingRef =
      FirebaseFirestore.instance.collection('bookings').doc(bookingId);

  try {
    final bookingSnapshot = await bookingRef.get();
    if (!bookingSnapshot.exists) return;

    final bookingData = bookingSnapshot.data()!;
    final email = bookingData['email'];

    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (userSnapshot.docs.isEmpty) return;

    final phone = userSnapshot.docs.first.data()['phone'] ?? '';

    await bookingRef.update({
      'status': 'Delivered',
      'deliveredBy': currentUser!.email,
      'deliveryDate': FieldValue.serverTimestamp(),
    });

    await sendNotificationToCargoOwner(
      context: context,
      phone: phone,
      title: isSindhi
          ? "توهان جو ڪارجو ترسيل ٿي ويو آهي!"
          : "Your cargo has been delivered!",
      body:
          "${bookingData['cargoType']} from ${bookingData['startCity']} to ${bookingData['endCity']} has been delivered by the truck owner.",
    );
  } catch (e) {
    print("❌ Error: $e");
  }
}

Future<void> acceptCargo(String bookingId, BuildContext context) async {
  if (currentUser == null) return;
  final isSindhi =
      Provider.of<LanguageProvider>(context, listen: false).isSindhi;
  final bookingRef =
      FirebaseFirestore.instance.collection('bookings').doc(bookingId);

  try {
    final bookingSnapshot = await bookingRef.get();
    final bookingData = bookingSnapshot.data()!;
    final email = bookingData['email'];

    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    final phone = userSnapshot.docs.first.data()['phone'] ?? '';

    await bookingRef.update({
      'status': 'Accepted',
      'acceptedBy': currentUser!.email,
    });

    await sendNotificationToCargoOwner(
      context: context,
      phone: phone,
      title: isSindhi
          ? "توهان جو ڪارجو قبول ٿي ويو آهي!"
          : "Your cargo has been accepted!",
      body:
          "${bookingData['cargoType']} from ${bookingData['startCity']} to ${bookingData['endCity']} has been accepted by a truck owner.",
    );
  } catch (e) {
    print("❌ Error: $e");
  }
}

Future<void> rejectCargo(String bookingId, BuildContext context) async {
  if (currentUser == null) return;

  final isSindhi =
      Provider.of<LanguageProvider>(context, listen: false).isSindhi;
  final bookingRef =
      FirebaseFirestore.instance.collection('bookings').doc(bookingId);

  try {
    final bookingSnapshot = await bookingRef.get();
    final bookingData = bookingSnapshot.data()!;
    final email = bookingData['email'];

    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    final phone = userSnapshot.docs.first.data()['phone'] ?? '';

    // 🚨 Only update rejectedBy, NOT status
    await bookingRef.update({
      'rejectedBy': FieldValue.arrayUnion([currentUser!.uid]),
    });

    await sendNotificationToCargoOwner(
      context: context,
      phone: phone,
      title: isSindhi
          ? "توهان جو ڪارجو رد ٿي ويو آهي!"
          : "Your cargo has been rejected!",
      body:
          "${bookingData['cargoType']} from ${bookingData['startCity']} to ${bookingData['endCity']} has been rejected by a truck owner.",
    );
  } catch (e) {
    print("❌ Error: $e");
  }
}

Future<void> sendNotificationToCargoOwner({
  required BuildContext context,
  required String phone,
  required String title,
  required String body,
}) async {
  try {
    final accessToken = await getAccessToken();
    if (accessToken == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('user_fcm_tokens')
        .where('phone', isEqualTo: phone)
        .get();

    for (var doc in snapshot.docs) {
      final token = doc.data()['fcmToken'];
      if (token == null || token.isEmpty) continue;

      final response = await http.post(
        Uri.parse(
            "https://fcm.googleapis.com/v1/projects/sindhtruckcargohub/messages:send"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken",
        },
        body: jsonEncode({
          "message": {
            "token": token,
            "notification": {"title": title, "body": body},
            "data": {"type": "cargo_response", "action": "update"},
          },
        }),
      );

      if (response.statusCode != 200) {
        print(
            "❌ Notification error: ${response.statusCode} - ${response.body}");
      }
    }
  } catch (e) {
    print("❌ Send Error: $e");
  }
}

Future<String?> getAccessToken() async {
  try {
    final String json =
        await rootBundle.loadString("assets/firebase-admin-key.json");
    final credentials =
        auth.ServiceAccountCredentials.fromJson(jsonDecode(json));
    final client = await auth.clientViaServiceAccount(credentials, [
      "https://www.googleapis.com/auth/firebase.messaging",
    ]);
    return client.credentials.accessToken.data;
  } catch (e) {
    print("❌ Token Error: $e");
    return null;
  }
}

Color getStatusColor(String status) {
  switch (status) {
    case 'Accepted':
      return Colors.green;
    case 'Rejected':
      return Colors.red;
    case 'Pending':
      return Colors.orange;
    default:
      return Colors.black;
  }
}
