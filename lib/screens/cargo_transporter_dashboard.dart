import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cargo_details.dart';
import 'available_trucks.dart';
import 'my_cargo.dart';
import 'cargo_tracking_screen.dart'; // <-- Import the new screen
import 'login_screen.dart'; // Ensure you have a login screen for redirection

class CargoTransporterDashboard extends StatefulWidget {
  @override
  _CargoTransporterDashboardState createState() =>
      _CargoTransporterDashboardState();
}

class _CargoTransporterDashboardState extends State<CargoTransporterDashboard> {
  int _selectedIndex = 0;

  // Dynamic list of available bookings for the logged-in user
  List<String> availableBookings = [];
  String? selectedBookingId;

  // Screens for each tab
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      MyCargoScreen(), // ✅ My Cargo Tab
      AvailableTrucksScreen(), // ✅ Available Trucks Tab
      CargoTrackingScreen(), // ✅ Cargo Tracking Tab
    ];
    fetchUserBookings(); // Fetch the user's bookings when the dashboard loads
  }

  // Fetch available bookings for the logged-in user
  Future<void> fetchUserBookings() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users') // Assuming each user has their own bookings
          .doc(userId)
          .collection('bookings') // Fetch bookings for the user
          .get();

      setState(() {
        availableBookings = querySnapshot.docs
            .map((doc) => doc.id) // Booking ID is used as the document ID
            .toList();
      });
    }
  }

  // Handle bottom navigation bar item selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Logout function to sign out from Firebase and navigate to login screen
  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(),
      ),
    );
  }

  // Function to handle booking selection (updated)
  void selectBooking(String? bookingId) {
    setState(() {
      selectedBookingId = bookingId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cargo Transporter Dashboard'),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Dropdown for selecting booking (only visible in Cargo Tracking Tab)

            Expanded(child: _screens[_selectedIndex]),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.white,
        backgroundColor: Colors.blue.shade900,
        unselectedItemColor: Colors.white60,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox),
            label: 'My Cargo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Available Trucks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Cargo Tracking',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
        onPressed: () {
          // Navigate to the Cargo Details Input screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CargoDetailsScreen()),
          );
        },
        child: const Icon(Icons.add, size: 28, color: Colors.white),
        tooltip: 'Add Cargo',
      ),
    );
  }
}
