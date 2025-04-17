import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class LiveCargoRequestsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isSindhi = Provider.of<LanguageProvider>(context).isSindhi;

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
          return Center(
              child: Text(isSindhi
                  ? 'هن وقت ڪا به اطلاع موجود ناهي.'
                  : 'No notifications at the moment.'));
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final doc = notifications[index];
            final data = doc.data() as Map<String, dynamic>;

            Timestamp? ts = data['timestamp'];
            String formattedTime = ts != null
                ? DateFormat('yyyy-MM-dd hh:mm a').format(ts.toDate())
                : (isSindhi ? 'اڻڄاتل وقت' : 'Unknown time');

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
                  SnackBar(
                    content: Text(
                      isSindhi ? "اطلاع ختم ڪئي وئي" : "Notification dismissed",
                    ),
                  ),
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
                      data['cargoDetails'] ??
                          (isSindhi ? 'نئون مال جي درخواست' : 'New Cargo Request'),
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
                          isSindhi
                              ? "کان: ${data['fromLocation']} ➡ ڏانهن: ${data['toLocation']}"
                              : "From: ${data['fromLocation']} ➡ To: ${data['toLocation']}",
                        ),
                        SizedBox(height: 2),
                        Text(isSindhi
                            ? "وزن: ${data['weight']} ڪلوگرام"
                            : "Weight: ${data['weight']} kg"),
                        SizedBox(height: 2),
                        Text(isSindhi
                            ? "فاصلو: ${data['distance']} ڪلوميٽر"
                            : "Distance: ${data['distance']} km"),
                        SizedBox(height: 2),
                        Text(isSindhi
                            ? "گاڏي جو قسم: ${data['vehicleType']}"
                            : "Vehicle Type: ${data['vehicleType']}"),
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
