import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'cargo_tracking_screen.dart';
import 'package:http/http.dart' as http;

class BookCargoScreen extends StatelessWidget {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final bool isSindhi = false; // Replace with actual language check
  void _markAsDelivered(String bookingId, BuildContext context) async {
    if (currentUser == null) return;

    final bookingRef =
        FirebaseFirestore.instance.collection('bookings').doc(bookingId);

    try {
      // Fetch booking data
      final bookingSnapshot = await bookingRef.get();
      if (!bookingSnapshot.exists) {
        print("❌ Booking not found with ID: $bookingId");
        return;
      }
      final bookingData = bookingSnapshot.data() as Map<String, dynamic>;

      print("🔧 Booking Data for delivery: $bookingData");

      // Get the phone number of the user who requested the cargo
      final email = bookingData['email'];
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        print("❌ No user found with email: $email");
        return;
      }

      final phone = userSnapshot.docs.first.data()['phone'] ?? '';
      print("🔧 Cargo Owner Phone: $phone");

      // Update the booking status to Delivered
      await bookingRef.update({
        'status': 'Delivered',
        'deliveredBy': currentUser!.email,
        'deliveryDate': FieldValue.serverTimestamp(),
      });

      print("✅ Cargo marked as Delivered!");

      final cargoType = bookingData['cargoType'];
      final start = bookingData['startCity'];
      final end = bookingData['endCity'];

      // Notify the user that the cargo is delivered
      await sendNotificationToCargoOwner(
        phone: phone,
        title: isSindhi
            ? "توهان جو ڪارجو ترسيل ٿي ويو آهي!"
            : "Your cargo has been delivered!",
        body:
            "$cargoType from $start to $end has been delivered by the truck owner.",
      );
    } catch (e) {
      // Specific error handling to catch any issues with Firestore operations
      print("❌ Error marking cargo as delivered: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isSindhi ? "ڪارجو ڪتاب ڪريو" : "Book Cargo Requests",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text(isSindhi
                    ? "❌ بوڪنگس لوڊ ڪرڻ ۾ غلطي!"
                    : "❌ Error loading bookings!"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          var bookings = snapshot.data?.docs ?? [];

          // Exclude bookings rejected or removed by this Truck Owner
          bookings = bookings.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            List<dynamic> rejectedBy = data['rejectedBy'] ?? [];
            List<dynamic> removedBy = data['removedBy'] ?? [];
            return !(rejectedBy.contains(currentUser?.uid) ||
                removedBy.contains(currentUser?.uid));
          }).toList();

          if (bookings.isEmpty) {
            return Center(
                child: Text(isSindhi
                    ? "ڪابه بوڪنگ دستياب ناهي."
                    : "No bookings available."));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              var bookingDoc = bookings[index];
              var bookingData = bookingDoc.data() as Map<String, dynamic>;
              String bookingId = bookingDoc.id;

              String status = bookingData['status'] ?? 'Pending';
              String acceptedBy = bookingData['acceptedBy'] ?? '';
              String requestedByEmail = bookingData['email'] ?? '';

              bool isAcceptedByAnother =
                  status == "Accepted" && acceptedBy != currentUser?.email;
              String displayStatus = isAcceptedByAnother
                  ? (isSindhi ? "دستياب ناهي" : "Not Available")
                  : status;

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: requestedByEmail)
                    .limit(1)
                    .get(),
                builder: (context, userSnapshot) {
                  String requestedByPhone =
                      isSindhi ? "لوڊ ٿي رهيو آهي..." : "Loading...";

                  if (userSnapshot.connectionState == ConnectionState.done) {
                    if (userSnapshot.hasData &&
                        userSnapshot.data!.docs.isNotEmpty) {
                      var userData = userSnapshot.data!.docs.first.data()
                          as Map<String, dynamic>;
                      requestedByPhone = userData['phone'] ??
                          (isSindhi ? "فراہم ناهي" : "Not Provided");
                    } else {
                      requestedByPhone =
                          isSindhi ? "يوزر نٿو ملي" : "User not found";
                      print("📛 No user found with email $requestedByEmail");
                    }
                  }

                  if (userSnapshot.hasError) {
                    print("❌ Error fetching phone: ${userSnapshot.error}");
                  }

                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_shipping,
                                  color: Colors.blue, size: 30),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "${isSindhi ? 'ڪارجو:' : 'Cargo:'} ${bookingData['cargoType'] ?? 'N/A'}",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                              "${isSindhi ? 'کان:' : 'From:'} ${bookingData['startCity'] ?? 'Unknown'}"),
                          Text(
                              "${isSindhi ? 'تائئن:' : 'To:'} ${bookingData['endCity'] ?? 'Unknown'}"),
                          Text(
                              "${isSindhi ? 'وزن:' : 'Weight:'} ${bookingData['weight']} tons"),
                          Text(
                              "${isSindhi ? 'فاصلو:' : 'Distance:'} ${bookingData['distance']} km"),
                          Text(
                              "${isSindhi ? 'قيمت:' : 'Price:'} Rs. ${bookingData['price']}"),
                          Text(
                              "${isSindhi ? 'فون:' : 'Phone:'} $requestedByPhone"),
                          Text(
                            "${isSindhi ? 'حالت:' : 'Status:'} $displayStatus",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(displayStatus),
                            ),
                          ),
                          SizedBox(height: 10),
                          if (status == 'Pending')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _acceptCargo(bookingId, context),
                                  icon: Icon(Icons.check, color: Colors.white),
                                  label:
                                      Text(isSindhi ? "قبول ڪريو" : "Accept"),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _rejectCargo(bookingId, context),
                                  icon: Icon(Icons.cancel, color: Colors.white),
                                  label: Text(isSindhi ? "رد ڪريو" : "Reject"),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white),
                                ),
                              ],
                            ),
                          if (status == "Accepted" &&
                              acceptedBy == currentUser?.email)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _markAsDelivered(bookingId, context),
                                  icon: Icon(Icons.check_circle,
                                      color: Colors.white),
                                  label: Text(isSindhi
                                      ? "پورو ٿي ويو"
                                      : "Mark as Delivered"),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                          255, 56, 145, 218),
                                      foregroundColor: Colors.white),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CargoTrackingScreen(
                                          bookingId: bookingId,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.location_on,
                                      color: Colors.white),
                                  label: Text(isSindhi ? "ٽريڪ ڪريو" : "Track"),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                          255, 146, 96, 231),
                                      foregroundColor: Colors.white),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
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

      print("✅ Access token retrieved: ${client.credentials.accessToken.data}");
      return client.credentials.accessToken.data;
    } catch (e) {
      print("❌ Error getting OAuth token: $e");
      return null;
    }
  }

  Future<void> sendNotificationToCargoOwner({
    required String phone,
    required String title,
    required String body,
  }) async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        print("❌ Failed to get OAuth token.");
        return;
      }

      // Query using phone number
      final snapshot = await FirebaseFirestore.instance
          .collection('user_fcm_tokens')
          .where('phone', isEqualTo: phone)
          .get();

      if (snapshot.docs.isEmpty) {
        print("❌ No FCM token found for phone: $phone");
        return;
      }

      for (var doc in snapshot.docs) {
        final token = doc.data()['fcmToken'];
        if (token == null || token.isEmpty) {
          print("❌ Invalid or empty FCM token for phone: $phone");
          continue;
        }

        final payload = {
          "message": {
            "token": token,
            "notification": {
              "title": title,
              "body": body,
            },
            "data": {
              "type": "cargo_response",
              "action": title.contains("accepted") ? "accepted" : "rejected",
            },
          }
        };

        final response = await http.post(
          Uri.parse(
              "https://fcm.googleapis.com/v1/projects/sindhtruckcargohub/messages:send"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $accessToken",
          },
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200) {
          print("✅ Notification sent to: $phone");
        } else {
          print("❌ FCM error: ${response.statusCode} - ${response.body}");
        }
      }
    } catch (e) {
      print("❌ Error sending notification: $e");
    }
  }

  void _acceptCargo(String bookingId, BuildContext context) async {
    if (currentUser == null) return;

    final bookingRef =
        FirebaseFirestore.instance.collection('bookings').doc(bookingId);

    try {
      final bookingSnapshot = await bookingRef.get();
      final bookingData = bookingSnapshot.data() as Map<String, dynamic>;

      // Debugging: Check if the booking is being fetched correctly
      print("🔧 Booking Data: $bookingData");

      // Get phone number of cargo owner
      final email = bookingData['email'];
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      final phone = userSnapshot.docs.isNotEmpty
          ? userSnapshot.docs.first.data()['phone'] ?? ''
          : '';
      print("🔧 Cargo Owner Phone: $phone");

      await bookingRef.update({
        'status': 'Accepted',
        'acceptedBy': currentUser!.email,
      });

      print("✅ Cargo Accepted!");

      final cargoType = bookingData['cargoType'];
      final start = bookingData['startCity'];
      final end = bookingData['endCity'];

      await sendNotificationToCargoOwner(
        phone: phone,
        title: isSindhi
            ? "توهان جو ڪارجو قبول ٿي ويو آهي!"
            : "Your cargo has been accepted!",
        body:
            "$cargoType from $start to $end has been accepted by a truck owner.",
      );
    } catch (e) {
      print("❌ Error accepting cargo: $e");
    }
  }

  void _rejectCargo(String bookingId, BuildContext context) async {
    if (currentUser == null) return;

    final bookingRef =
        FirebaseFirestore.instance.collection('bookings').doc(bookingId);

    try {
      final bookingSnapshot = await bookingRef.get();
      final bookingData = bookingSnapshot.data() as Map<String, dynamic>;

      // Get phone number of cargo owner
      final email = bookingData['email'];
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      final phone = userSnapshot.docs.isNotEmpty
          ? userSnapshot.docs.first.data()['phone'] ?? ''
          : '';
      print("🔧 Cargo Owner Phone: $phone");

      await bookingRef.update({
        'status': 'Rejected',
        'rejectedBy': FieldValue.arrayUnion([currentUser!.uid]),
      });

      print("✅ Cargo Rejected!");

      final cargoType = bookingData['cargoType'];
      final start = bookingData['startCity'];
      final end = bookingData['endCity'];

      // 🚀 Send reject notification
      await sendNotificationToCargoOwner(
        phone: phone,
        title: isSindhi
            ? "توهان جو ڪارجو رد ٿي ويو آهي!"
            : "Your cargo has been rejected!",
        body:
            "$cargoType from $start to $end has been rejected by a truck owner.",
      );
    } catch (e) {
      print("❌ Error rejecting cargo: $e");
    }
  }

  Color _getStatusColor(String status) {
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
}
