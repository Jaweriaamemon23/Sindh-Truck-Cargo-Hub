import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'business_owner_functions.dart';
import '../providers/language_provider.dart';

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
      print("Tab selected: $index");
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSindhi = Provider.of<LanguageProvider>(context).isSindhi;

    List<Widget> screens = [
      isLoading
          ? Center(child: CircularProgressIndicator())
          : BusinessOwnerFunctions.getTrackShipmentScreen(context) ??
              Center(child: Text("Error: Track Shipment screen is null")),
      Center(child: Text(isSindhi ? "بلانس ڏسو" : "View Invoice")),
      Center(
          child: Text(isSindhi ? "پٽڻ جي حيثيت ڏسو" : "View Shipment Status")),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: Text(
          isSindhi ? "ڪاروباري مالڪ ڊيش بورڊ" : "Business Owner Dashboard",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              print("Logging out...");
              BusinessOwnerFunctions.logout(context);
            },
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Secondary "AppBar"
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.blue.shade800,
            child: Text(
              isSindhi ? 'منهنجون روانگيون' : 'My Shipments',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
