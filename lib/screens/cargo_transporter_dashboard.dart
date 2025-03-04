import 'package:flutter/material.dart';
import 'cargo_details.dart'; // Import the cargo details screen

class CargoTransporterDashboard extends StatefulWidget {
  @override
  _CargoTransporterDashboardState createState() =>
      _CargoTransporterDashboardState();
}

class _CargoTransporterDashboardState extends State<CargoTransporterDashboard> {
  int _selectedIndex = 0;

  // List of screens for each tab
  final List<Widget> _screens = [
    Center(child: Text('View Available Cargo')),
    Center(child: Text('Track Shipment')),
    Center(child: Text('Send Availability Notifications')),
  ];

  // Function to handle tab index change
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cargo Transporter Dashboard'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _screens[_selectedIndex], // Show content based on the selected tab
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Available Cargo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_boat),
            label: 'Track Shipment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Send Availability Notifications',
          ),
        ],
      ),

      // **Floating Action Button for Adding Cargo Details**
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900, // Button color
        onPressed: () {
          // Navigate to Cargo Details Screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CargoDetailsScreen()),
          );
        },
        child: Icon(Icons.local_shipping, size: 28, color: Colors.white), // Truck icon
        tooltip: 'Add Cargo Details',
      ),
    );
  }
}
