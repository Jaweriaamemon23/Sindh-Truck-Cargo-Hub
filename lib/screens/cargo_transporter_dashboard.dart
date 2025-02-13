import 'package:flutter/material.dart';

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
        // Apply gradient background to the body
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade100,
              Colors.blue.shade300
            ], // Gradient colors
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child:
            _screens[_selectedIndex], // Show content based on the selected tab
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // Update the selected tab
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box), // Icon for Available Cargo
            label: 'Available Cargo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_boat), // Icon for Track Shipment
            label: 'Track Shipment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications), // Icon for Send Notifications
            label: 'Send Availability Notifications',
          ),
        ],
      ),
    );
  }
}

