import 'package:flutter/material.dart';
import 'business_owner_functions.dart';

class BusinessOwnerDashboard extends StatefulWidget {
  @override
  _BusinessOwnerDashboardState createState() => _BusinessOwnerDashboardState();
}

class _BusinessOwnerDashboardState extends State<BusinessOwnerDashboard> {
  int _selectedIndex = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Debugging log added
    print("Fetching bookings for business owner...");

    BusinessOwnerFunctions.fetchBookingsForBusinessOwner(context, (bookings) {
      if (bookings == null || bookings.isEmpty) {
        print("No bookings found for business owner.");
      } else {
        print("Fetched ${bookings.length} bookings.");
      }
      setState(() {
        isLoading = false;
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      print("Tab selected: $index"); // Debugging tab selection
    });
  }

  List<Widget> getScreens() {
    return [
      isLoading
          ? Center(child: CircularProgressIndicator())
          : BusinessOwnerFunctions.getTrackShipmentScreen() ??
              Center(child: Text("Error: Track Shipment screen is null")),
      Center(child: Text('View Invoice')),
      Center(child: Text('View Shipment Status')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Business Owner Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              print("Logging out..."); // Debugging logout
              BusinessOwnerFunctions.logout(context);
            },
          )
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
        child: getScreens()[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
