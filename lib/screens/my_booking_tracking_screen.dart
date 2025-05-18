import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyBookingTrackingScreen extends StatefulWidget {
  @override
  _MyBookingTrackingScreenState createState() =>
      _MyBookingTrackingScreenState();
}

class _MyBookingTrackingScreenState extends State<MyBookingTrackingScreen> {
  final TextEditingController _bookingIdController = TextEditingController();
  List<DocumentSnapshot> _trackingData = [];
  bool _isLoading = false;
  String? _error;

  Future<void> _fetchTrackingData() async {
    final bookingId = _bookingIdController.text.trim();
    if (bookingId.isEmpty) {
      setState(() {
        _error = 'Please enter a booking ID';
        _trackingData = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('cargo_tracking')
          .doc(bookingId)
          .collection('progress')
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        _trackingData = snapshot.docs;
        if (_trackingData.isEmpty) {
          _error = 'No tracking data found for this booking ID';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch tracking data';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _bookingIdController,
            decoration: InputDecoration(
              labelText: 'Enter Booking ID',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _fetchTrackingData,
            child: Text('Track Booking'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              foregroundColor:
                  Colors.white, // ✅ sets the text/icon color to white
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            CircularProgressIndicator()
          else if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Colors.red),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _trackingData.length,
                itemBuilder: (context, index) {
                  final data =
                      _trackingData[index].data() as Map<String, dynamic>;
                  final city = data['city'] ?? 'Unknown';

                  final rawTime = data['timestamp'];
                  final time = rawTime is Timestamp
                      ? rawTime.toDate().toString()
                      : rawTime?.toString() ?? 'N/A';

                  return Card(
                    child: ListTile(
                      leading: Icon(Icons.location_on),
                      title: Text('Location: $city'),
                      subtitle: Text('Time: $time'),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
