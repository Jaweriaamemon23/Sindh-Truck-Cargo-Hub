import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'business_owner_functions.dart';
import '../providers/language_provider.dart'; // Import LanguageProvider

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
          : BusinessOwnerFunctions.getTrackShipmentScreen(context) ??
              Center(child: Text("Error: Track Shipment screen is null")),
      Center(
          child: Text(
              Provider.of<LanguageProvider>(context, listen: false).isSindhi
                  ? "بلانس ڏسو"
                  : "View Invoice")),
      Center(
          child: Text(
              Provider.of<LanguageProvider>(context, listen: false).isSindhi
                  ? "پٽڻ جي حيثيت ڏسو"
                  : "View Shipment Status")),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            Provider.of<LanguageProvider>(context, listen: false).isSindhi
                ? "ڪاروباري مالڪ ڊيش بورڊ"
                : "Business Owner Dashboard"),
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
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label:
                Provider.of<LanguageProvider>(context, listen: false).isSindhi
                    ? 'پٽڻ ٽريڪ'
                    : 'Track Shipment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label:
                Provider.of<LanguageProvider>(context, listen: false).isSindhi
                    ? 'بلانس ڏسو'
                    : 'View Invoice',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label:
                Provider.of<LanguageProvider>(context, listen: false).isSindhi
                    ? 'پٽڻ جي حيثيت ڏسو'
                    : 'View Shipment Status',
          ),
        ],
      ),
    );
  }
}
