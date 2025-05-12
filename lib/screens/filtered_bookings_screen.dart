import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For formatting timestamp

class FilteredBookingsScreen extends StatelessWidget {
  final String status;

  FilteredBookingsScreen({required this.status});

  final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

  @override
  Widget build(BuildContext context) {
    final isAll = status == "All";

    return Scaffold(
      appBar: AppBar(
        title: Text(isAll ? "All Bookings" : "$status Bookings"),
        backgroundColor: Colors.blue.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: isAll
            ? FirebaseFirestore.instance.collection('bookings').snapshots()
            : FirebaseFirestore.instance
                .collection('bookings')
                .where('status', isEqualTo: status)
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!.docs;

          if (bookings.isEmpty) {
            return Center(child: Text("No bookings with status '$status'."));
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index].data() as Map<String, dynamic>;

              String startCity = booking['startCity'] ?? 'N/A';
              String endCity = booking['endCity'] ?? 'N/A';
              String cargoType = booking['cargoType'] ?? 'N/A';
              String weight = booking['weight'] ?? 'N/A';
              String distance = booking['distance'] ?? 'N/A';
              num price = booking['price'] ?? 0;
              String acceptedBy = booking['acceptedBy'] ?? 'N/A';
              Timestamp? timestamp = booking['timestamp'];
              String formattedDate = timestamp != null
                  ? dateFormat.format(timestamp.toDate())
                  : 'Unknown';

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("$startCity ➝ $endCity",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text("🧱 Cargo Type: $cargoType"),
                      Text("⚖️ Weight: $weight kg"),
                      Text("🛣️ Distance: $distance km"),
                      Text("💰 Price: Rs. ${price.toStringAsFixed(0)}"),
                      Text("📦 Status: ${booking['status'] ?? 'Unknown'}"),
                      Text("👤 Accepted By: $acceptedBy"),
                      Text("📅 Booked At: $formattedDate"),
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
}
