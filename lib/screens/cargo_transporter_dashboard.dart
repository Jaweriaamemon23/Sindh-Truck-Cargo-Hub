import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cargo_details.dart';
import 'available_trucks.dart';
import 'my_cargo.dart';
import 'login_screen.dart'; // Ensure you have a login screen for redirection

class CargoTransporterDashboard extends StatefulWidget {
  @override
  _CargoTransporterDashboardState createState() =>
      _CargoTransporterDashboardState();
}

class _CargoTransporterDashboardState extends State<CargoTransporterDashboard> {
  int _selectedIndex = 0;

  // Screens for each tab
  final List<Widget> _screens = [
    MyCargoScreen(), // ✅ My Cargo Tab
    AvailableTrucksScreen(), // ✅ Available Trucks Tab
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()), // Redirect to Login
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cargo Transporter Dashboard'),
        backgroundColor: Colors.blue.shade900,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
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
        child: _screens[_selectedIndex],
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
        ],
      ),

      // Floating Action Button for Adding Cargo Details
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
        onPressed: () {
          // Navigate to the Cargo Details Input screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CargoDetailsScreen()),
          );
        },
        child: Icon(Icons.add, size: 28, color: Colors.white),
        tooltip: 'Add Cargo',
      ),
    );
  }
}