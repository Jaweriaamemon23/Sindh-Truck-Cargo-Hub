import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Replace with your actual tracking screen import
import 'cargo_tracking_screen.dart';

class BookCargoScreen extends StatelessWidget {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text("Book Cargo Requests", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("❌ Error loading bookings!"));
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
            return Center(child: Text("No bookings available."));
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
              String displayStatus =
                  isAcceptedByAnother ? "Not Available" : status;

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: requestedByEmail)
                    .limit(1)
                    .get(),
                builder: (context, userSnapshot) {
                  String requestedByPhone = "Loading...";

                  if (userSnapshot.connectionState == ConnectionState.done) {
                    if (userSnapshot.hasData &&
                        userSnapshot.data!.docs.isNotEmpty) {
                      var userData = userSnapshot.data!.docs.first.data()
                          as Map<String, dynamic>;
                      requestedByPhone = userData['phone'] ?? "Not Provided";
                    } else {
                      requestedByPhone = "User not found";
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
                                  "Cargo: ${bookingData['cargoType'] ?? 'N/A'}",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                              "From: ${bookingData['startCity'] ?? 'Unknown'}"),
                          Text("To: ${bookingData['endCity'] ?? 'Unknown'}"),
                          Text("Weight: ${bookingData['weight']} tons"),
                          Text("Distance: ${bookingData['distance']} km"),
                          Text("Price: Rs. ${bookingData['price']}"),
                          Text("Phone: $requestedByPhone"),
                          Text(
                            "Status: $displayStatus",
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
                                  label: Text("Accept"),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _rejectCargo(bookingId, context),
                                  icon: Icon(Icons.cancel, color: Colors.white),
                                  label: Text("Reject"),
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
                                  label: Text("Mark as Delivered"),
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
                                  label: Text("Track"),
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

  void _acceptCargo(String bookingId, BuildContext context) {
    if (currentUser == null) return;

    FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': 'Accepted',
      'acceptedBy': currentUser!.email,
    }).then((_) {
      print("✅ Cargo Accepted!");
    }).catchError((error) {
      print("❌ Error accepting cargo: $error");
    });
  }

  void _rejectCargo(String bookingId, BuildContext context) {
    if (currentUser == null) return;

    FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'rejectedBy': FieldValue.arrayUnion([currentUser!.email]),
    }).then((_) {
      print("🚫 Cargo Rejected!");
    }).catchError((error) {
      print("❌ Error rejecting cargo: $error");
    });
  }

  void _markAsDelivered(String bookingId, BuildContext context) {
    if (currentUser == null) return;

    FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': 'Delivered',
    }).then((_) {
      print("✅ Cargo Marked as Delivered!");
    }).catchError((error) {
      print("❌ Error marking cargo as delivered: $error");
    });
  }

  Color _getStatusColor(String? status) {
    if (status == "Accepted") return Colors.green;
    if (status == "Not Available") return Colors.grey;
    if (status == "Delivered") return Colors.blue;
    return Colors.orange;
  }
}
