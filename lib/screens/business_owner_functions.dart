import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ✅ Import provider
import 'login_screen.dart';
import 'cargo_tracking_screen.dart'; // Import the CargoTrackingScreen
import '../providers/language_provider.dart'; // ✅ Import the LanguageProvider

class BusinessOwnerFunctions {
  static List<Map<String, dynamic>> bookings = [];

  // Fetch business owner bookings from Firestore based on the user's phone
  static Future<void> fetchBookingsForBusinessOwner(
      BuildContext context, Function callback) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print("No user currently logged in.");
        return;
      }

      // Step 1: Get the current user's phone number
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: currentUser.email)
          .limit(1)
          .get();

      if (userSnapshot.docs.isEmpty) {
        print("No user found in Firestore with email: ${currentUser.email}");
        callback([]);
        return;
      }

      final phone = userSnapshot.docs.first.data()['phone'];
      print("Current user's phone: $phone");

      // Step 2: Get bookings where businessOwnerId == phone
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('businessOwnerId', isEqualTo: phone)
          .get();

      bookings = bookingsSnapshot.docs.map((doc) {
        // Add the document ID as the bookingId
        final bookingData = doc.data();
        bookingData['bookingId'] = doc.id;
        return bookingData;
      }).toList();

      print("Fetched ${bookings.length} bookings for business owner.");

      // Debugging: Print booking IDs
      bookings.forEach((booking) {
        print("Booking ID: ${booking['bookingId']}");
      });

      callback(bookings);
    } catch (e) {
      print('Error fetching bookings: $e');
      callback([]);
    }
  }

  // Handle logout functionality
  static void logout(BuildContext context) async {
    print("Logging out...");
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(),
      ),
    );
  }

  // Returns the screen for the 'Track Shipment' tab
  static Widget getTrackShipmentScreen(BuildContext context) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(
          Provider.of<LanguageProvider>(context, listen: false).isSindhi
              ? "ڪو به بڪنگ نه مليو."
              : "No bookings found.", // Dynamic text for no bookings found
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        final bookingId = booking['bookingId']; // Use the bookingId set earlier

        // Debugging: Log the bookingId
        print("Displaying Booking ID: $bookingId");

        return Card(
          elevation: 4,
          margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: Icon(Icons.local_shipping, color: Colors.blueAccent),
            title: Text(
              "${booking['startCity']} ➜ ${booking['endCity']}",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              Provider.of<LanguageProvider>(context, listen: false).isSindhi
                  ? "قبول ڪيو ويو: ${booking['acceptedBy']}"
                  : "Accepted By: ${booking['acceptedBy']}", // Dynamic text for accepted by
            ),
            onTap: () {
              // Pass the actual bookingId
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CargoTrackingScreen(
                    bookingId: bookingId, // Pass selected bookingId dynamically
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
