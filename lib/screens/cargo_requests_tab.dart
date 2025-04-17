import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Add this for formatting date

class LiveCargoRequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data?.docs ?? [];

        if (notifications.isEmpty) {
          return Center(child: Text('No notifications at the moment.'));
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final doc = notifications[index];
            final data = doc.data() as Map<String, dynamic>;

            // Extract and format timestamp
            Timestamp? ts = data['timestamp'];
            String formattedTime = ts != null
                ? DateFormat('yyyy-MM-dd hh:mm a').format(ts.toDate())
                : 'Unknown time';

            return Dismissible(
              key: Key(doc.id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20),
                child: Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) async {
                await FirebaseFirestore.instance
                    .collection('notifications')
                    .doc(doc.id)
                    .delete();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Notification dismissed")),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    title: Text(
                      data['cargoDetails'] ?? 'New Cargo Request',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          formattedTime,
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        SizedBox(height: 4),
                        Text(
                            "From: ${data['fromLocation']} ➡ To: ${data['toLocation']}"),
                        SizedBox(height: 2),
                        Text("Weight: ${data['weight']} kg"),
                        SizedBox(height: 2),
                        Text("Distance: ${data['distance']} km"),
                        SizedBox(height: 2),
                        Text("Vehicle Type: ${data['vehicleType']}"),
                      ],
                    ),
                    trailing: Icon(Icons.local_shipping, color: Colors.blue),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
