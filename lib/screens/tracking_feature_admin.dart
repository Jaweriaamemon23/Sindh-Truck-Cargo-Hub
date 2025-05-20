import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cargo Transporters',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('userType', isEqualTo: 'Cargo Transporter')
            .where('verified', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No cargo transporters found.'));
          }

          final transporters = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: transporters.length,
            itemBuilder: (context, index) {
              final transporter = transporters[index];
              final data = transporter.data() as Map<String, dynamic>;

              // Skip specific users
              if (transporter.id == '03333139670' ||
                  data['email'] == 'sindhtruckcargohub@gmail.com') {
                return const SizedBox.shrink();
              }

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  leading:
                      const Icon(Icons.person, color: Colors.blue, size: 40),
                  title: Text(
                    data['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NIC: ${data['nic'] ?? 'N/A'}'),
                      Text('Phone: ${data['phone'] ?? 'N/A'}'),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TransporterBookingsScreen(
                          email: data['email'],
                          name: data['name'] ?? 'Unknown',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class TransporterBookingsScreen extends StatelessWidget {
  final String email;
  final String name;

  const TransporterBookingsScreen({
    Key? key,
    required this.email,
    required this.name,
  }) : super(key: key);

  String _formattedTimestamp({DateTime? date}) {
    final now = date ?? DateTime.now();
    return DateFormat('dd MMM yyyy – hh:mm a').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$name\'s Bookings',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('email', isEqualTo: email)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No bookings found.'));
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final data = booking.data() as Map<String, dynamic>;
              final bookingId = booking.id;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ExpansionTile(
                  title: Text(
                    'Booking ID: ${data['bookingId'] ?? bookingId}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  subtitle: Text(
                    'Status: ${data['status'] ?? 'Unknown'}\n'
                    'Route: ${data['startCity'] ?? 'Unknown'} → ${data['endCity'] ?? 'Unknown'}',
                  ),
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('cargo_tracking')
                          .doc(bookingId)
                          .collection('progress')
                          .orderBy('timestamp')
                          .snapshots(),
                      builder: (context, trackingSnapshot) {
                        if (trackingSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (!trackingSnapshot.hasData ||
                            trackingSnapshot.data!.docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No tracking data available yet.'),
                          );
                        }

                        final progressDocs = trackingSnapshot.data!.docs;

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: progressDocs.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final progressData = progressDocs[index].data()
                                as Map<String, dynamic>;
                            final city = progressData['city'] ?? 'Unknown';
                            final timestamp =
                                progressData['timestamp'] ?? 'Unknown';

                            return ListTile(
                              leading: const Icon(Icons.location_on,
                                  color: Colors.blue),
                              title: Text(city.toUpperCase()),
                              subtitle: Text(timestamp),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
