import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookCargoScreen extends StatelessWidget {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Book Cargo Requests", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("❌ Error loading bookings!"));
          if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());

          var bookings = snapshot.data?.docs ?? [];

          // Exclude bookings rejected or removed by this Truck Owner
          bookings = bookings.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            List<dynamic> rejectedBy = data['rejectedBy'] ?? [];
            List<dynamic> removedBy = data['removedBy'] ?? [];
            return !(rejectedBy.contains(currentUser?.uid) || removedBy.contains(currentUser?.uid));
          }).toList();

          if (bookings.isEmpty) return Center(child: Text("No bookings available."));

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              var bookingData = bookings[index].data() as Map<String, dynamic>;
              String bookingId = bookings[index].id;

              String status = bookingData['status'] ?? 'Pending';
              String acceptedBy = bookingData['acceptedBy'] ?? '';

              // If another truck owner has accepted, show "Not Available" for others
              bool isAcceptedByAnother = status == "Accepted" && acceptedBy != currentUser?.uid;
              String displayStatus = isAcceptedByAnother ? "Not Available" : status;

              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.local_shipping, color: Colors.blue, size: 30),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "Cargo: ${bookingData['cargoType'] ?? 'N/A'}",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text("From: ${bookingData['startCity'] ?? 'Unknown'}"),
                      Text("To: ${bookingData['endCity'] ?? 'Unknown'}"),
                      Text("Weight: ${bookingData['weight']} kg"),
                      Text("Distance: ${bookingData['distance']} km"),
                      Text("Price: Rs. ${bookingData['price']}"),
                      Text(
                        "Status: $displayStatus",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(displayStatus),
                        ),
                      ),
                      SizedBox(height: 10),

                      /// ✅ Show Accept/Reject buttons only if status is Pending
                      if (status == 'Pending')
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _acceptCargo(bookingId),
                              icon: Icon(Icons.check, color: Colors.white),
                              label: Text("Accept"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _rejectCargo(bookingId),
                              icon: Icon(Icons.cancel, color: Colors.white),
                              label: Text("Reject"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            ),
                          ],
                        ),

                      /// ✅ Show Remove Button if Cargo is "Not Available"
                      if (displayStatus == "Not Available")
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: () => _removeCargo(bookingId),
                            icon: Icon(Icons.delete, color: Colors.white),
                            label: Text("Remove"),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// ✅ Accept Cargo (Updates Firestore)
  void _acceptCargo(String bookingId) {
    if (currentUser == null) return;

    FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': 'Accepted',
      'acceptedBy': currentUser!.uid, // Save the Truck Owner who accepted
    }).then((_) {
      print("✅ Cargo Accepted!");
    }).catchError((error) {
      print("❌ Error accepting cargo: $error");
    });
  }

  /// ✅ Reject Cargo (Removes Only for Current User)
  void _rejectCargo(String bookingId) {
    if (currentUser == null) return;

    FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'rejectedBy': FieldValue.arrayUnion([currentUser!.uid]), // Add user to rejected list
    }).then((_) {
      print("🚫 Cargo Rejected!");
    }).catchError((error) {
      print("❌ Error rejecting cargo: $error");
    });
  }

  /// ✅ Remove "Not Available" Cargo (Removes Only for Current User)
  void _removeCargo(String bookingId) {
    if (currentUser == null) return;

    FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'removedBy': FieldValue.arrayUnion([currentUser!.uid]), // Add user to removed list
    }).then((_) {
      print("🚫 Cargo Removed from Dashboard!");
    }).catchError((error) {
      print("❌ Error removing cargo: $error");
    });
  }

  /// ✅ Status Color Helper
  Color _getStatusColor(String? status) {
    if (status == "Accepted") return Colors.green;
    if (status == "Not Available") return Colors.grey;
    return Colors.orange;
  }
}
