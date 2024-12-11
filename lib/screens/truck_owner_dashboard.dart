import 'package:flutter/material.dart';

class TruckOwnerDashboard extends StatefulWidget {
  @override
  _TruckOwnerDashboardState createState() => _TruckOwnerDashboardState();
}

class _TruckOwnerDashboardState extends State<TruckOwnerDashboard> {
  int _selectedIndex = 0;

  // List of screens for each tab
  final List<Widget> _screens = [
    Center(child: Text('View Truck Status', style: TextStyle(fontSize: 20))),
    Center(child: Text('Manage Vehicles', style: TextStyle(fontSize: 20))),
    Center(child: Text('Book Cargo', style: TextStyle(fontSize: 20))),
    Center(child: Text('View Notifications', style: TextStyle(fontSize: 20))),
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
        title: Text('Truck Owner Dashboard'), // Set AppBar color
      ),
      body: Container(
        // Apply gradient background to the body
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade100,
              Colors.blue.shade300,
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
        backgroundColor: Colors
            .blue.shade800, // Set background color for the BottomNavigationBar
        selectedItemColor:
            Colors.black, // Color of the selected item (text + icon)
        unselectedItemColor:
            Colors.black, // Color of the unselected items (text + icon)
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping), // Icon for View Truck Status
            label: 'View Truck Status',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box), // Icon for Manage Vehicles
            label: 'Manage Vehicles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book), // Icon for Book Cargo
            label: 'Book Cargo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications), // Icon for Notifications
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}
