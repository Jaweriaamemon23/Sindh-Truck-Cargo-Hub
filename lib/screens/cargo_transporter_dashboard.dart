import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cargo_details.dart';
import 'available_trucks.dart';
import 'my_cargo.dart';
import 'cargo_tracking_screen.dart'; // <-- Import the new screen
import 'login_screen.dart'; // Ensure you have a login screen for redirection
import 'package:provider/provider.dart';
import 'package:sindh_truck_cargo_hub/providers/language_provider.dart' as langProvider; // Using alias

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
      MaterialPageRoute(
        builder: (context) => LoginScreen(),
      ),
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
        title: Text(isSindhi ? 'ڪارگو ٽرانسپورٽر ڊيش بورڊ' : 'Cargo Transporter Dashboard'),
        backgroundColor: Colors.blue.shade900,
        actions: [
          // Language Toggle Button
          IconButton(
            icon: Icon(isSindhi ? Icons.language : Icons.translate),
            onPressed: () {
              Provider.of<LanguageProvider>(context, listen: false).toggleLanguage();
            },
            tooltip: isSindhi ? 'ٻولي تبديل ڪريو' : 'Change Language',
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: isSindhi ? 'سائن آئوٽ' : 'Logout',
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
            label: isSindhi ? 'ڪارگو جي نگراني' : 'Cargo Tracking',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CargoDetailsScreen()),
          );
        },
        child: const Icon(Icons.add, size: 28, color: Colors.white),
        tooltip: isSindhi ? 'نئون ڪارگو شامل ڪريو' : 'Add Cargo',
      ),
    );
  }
}
