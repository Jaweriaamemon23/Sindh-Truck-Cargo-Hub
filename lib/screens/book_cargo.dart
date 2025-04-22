import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'cargo_tracking_screen.dart';
import 'cargo_actions.dart';
import '../providers/language_provider.dart'; // <-- Add this line
import 'package:provider/provider.dart'; // <-- Add this too

class BookCargoScreen extends StatelessWidget {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final isSindhi =
        Provider.of<LanguageProvider>(context).isSindhi; // <-- Dynamic language

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSindhi ? "ڪارجو ڪتاب ڪريو" : "Book Cargo Requests",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(isSindhi
                  ? "❌ بوڪنگس لوڊ ڪرڻ ۾ غلطي!"
                  : "❌ Error loading bookings!"),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          var bookings = snapshot.data?.docs ?? [];

          bookings = bookings.where((doc) {
            var data = doc.data() as Map<String, dynamic>;
            List<dynamic> rejectedBy = data['rejectedBy'] ?? [];
            List<dynamic> removedBy = data['removedBy'] ?? [];
            return !(rejectedBy.contains(currentUser?.uid) ||
                removedBy.contains(currentUser?.uid));
          }).toList();

          if (bookings.isEmpty) {
            return Center(
              child: Text(
                isSindhi ? "ڪابه بوڪنگ دستياب ناهي." : "No bookings available.",
              ),
            );
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
                    }
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
                                  "${isSindhi ? 'ڪارگو:' : 'Cargo:'} ${bookingData['cargoType'] ?? 'N/A'}",
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
                                color: getStatusColor(displayStatus)),
                          ),
                          SizedBox(height: 10),
                          if (status == 'Pending')
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      acceptCargo(bookingId, context),
                                  icon: Icon(Icons.check, color: Colors.white),
                                  label:
                                      Text(isSindhi ? "قبول ڪريو" : "Accept"),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      rejectCargo(bookingId, context),
                                  icon: Icon(Icons.cancel, color: Colors.white),
                                  label: Text(isSindhi ? "رد ڪريو" : "Reject"),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
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
                                      markAsDelivered(bookingId, context),
                                  icon: Icon(Icons.check_circle,
                                      color: Colors.white),
                                  label: Text(isSindhi
                                      ? "پورو ٿي ويو"
                                      : "Mark as Delivered"),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => CargoTrackingScreen(
                                            bookingId: bookingId),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.location_on,
                                      color: Colors.white),
                                  label: Text(isSindhi ? "ٽريڪ ڪريو" : "Track",
                                  ),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple),
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
}