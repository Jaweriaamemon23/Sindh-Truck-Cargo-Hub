import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import 'cargo_details.dart';
import 'available_trucks.dart';
import 'my_cargo.dart';
import 'cargo_tracking_screen.dart';
import 'login_screen.dart';

// ✅ NEW: Import your MyBookingTrackingScreen
import 'my_booking_tracking_screen.dart'; // <-- You must create this screen

class CargoTransporterDashboard extends StatefulWidget {
  @override
  _CargoTransporterDashboardState createState() =>
      _CargoTransporterDashboardState();
}

class _CargoTransporterDashboardState extends State<CargoTransporterDashboard> {
  int _selectedIndex = 0;

  List<String> availableBookings = [];
  String? selectedBookingId;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      MyCargoScreen(),
      AvailableTrucksScreen(),
      CargoTrackingScreen(),
      MyBookingTrackingScreen(), // ✅ NEW screen added here
    ];
    fetchUserBookings();
  }

  Future<void> fetchUserBookings() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bookings')
          .get();

      setState(() {
        availableBookings = querySnapshot.docs.map((doc) => doc.id).toList();
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  void selectBooking(String? bookingId) {
    setState(() {
      selectedBookingId = bookingId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSindhi = Provider.of<LanguageProvider>(context).isSindhi;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSindhi
              ? 'ڪارگو ٽرانسپورٽر ڊيش بورڊ'
              : 'Cargo Transporter Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: isSindhi ? 'لاگ آئوٽ' : 'Logout',
          ),
          IconButton(
            icon: Icon(Icons.language, color: Colors.white),
            tooltip: isSindhi ? 'ٻولي مٽايو' : 'Change Language',
            onPressed: () {
              Provider.of<LanguageProvider>(context, listen: false)
                  .toggleLanguage();
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // ✅ important
        backgroundColor:
            Colors.blue.shade800, // ✅ ensures blue color is applied
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox),
            label: isSindhi ? 'منهنجو ڪارگو' : 'My Cargo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: isSindhi ? 'دستياب ٽرڪون' : 'Available Trucks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: isSindhi ? 'ڪارگو ٽريڪنگ' : 'Cargo Tracking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: isSindhi ? 'ٽريڪنگ ID سان' : 'Track by ID',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade800,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CargoDetailsScreen()),
          );
        },
        child: Icon(Icons.add, size: 28, color: Colors.white),
        tooltip: isSindhi ? 'نئون ڪارگو شامل ڪريو' : 'Add Cargo',
      ),
    );
  }
}
