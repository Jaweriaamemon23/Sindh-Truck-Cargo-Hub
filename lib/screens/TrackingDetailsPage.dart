import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class TrackingDetailsPage extends StatelessWidget {
  final String bookingId;

  TrackingDetailsPage({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tracking Details"),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('cargo_tracking')
            .doc(bookingId)
            .collection('progress')
            .orderBy('timestamp', descending: true)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final trackingData = snapshot.data!.docs;

          if (trackingData.isEmpty) {
            return Center(
              child: Text("No tracking data found"),
            );
          }

          return ListView.builder(
            itemCount: trackingData.length,
            itemBuilder: (context, index) {
              final data = trackingData[index].data() as Map<String, dynamic>;
              final city = data['city'] ?? 'Unknown';
              final time = data['timestamp'] ?? 'N/A';

              return Card(
                child: ListTile(
                  title: Text("Location: $city"),
                  subtitle: Text("Time: $time"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
