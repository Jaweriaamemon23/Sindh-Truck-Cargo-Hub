import 'package:flutter/material.dart';

class BusinessOwnerDashboard extends StatefulWidget {
  @override
  _BusinessOwnerDashboardState createState() => _BusinessOwnerDashboardState();
}

class _BusinessOwnerDashboardState extends State<BusinessOwnerDashboard> {
  int _selectedIndex = 0;

  // List of screens for each tab
  final List<Widget> _screens = [
    Center(child: Text('Track Shipment')),
    Center(child: Text('View Invoice')),
    Center(child: Text('View Shipment Status')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Business Owner Dashboard'),
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
            icon: Icon(Icons.local_shipping),
            label: 'Track Shipment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'View Invoice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'View Shipment Status',
          ),
        ],
      ),
    );
  }
}
