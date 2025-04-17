import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sindh_truck_cargo_hub/screens/truck_owner_reviews.dart';
import 'book_cargo.dart';
import 'my_trucks.dart';
import 'login_screen.dart';
import 'cargo_requests_tab.dart';
import 'package:provider/provider.dart';
import 'package:sindh_truck_cargo_hub/providers/language_provider.dart'; // Import your LanguageProvider

class TruckOwnerDashboard extends StatefulWidget {
  @override
  _TruckOwnerDashboardState createState() => _TruckOwnerDashboardState();
}

class _TruckOwnerDashboardState extends State<TruckOwnerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    MyTrucksScreen(), // ✅ Now calling it as a separate screen
    BookCargoScreen(),
    TruckOwnerReviewsScreen(), // ✅ Reviews Screen
    LiveCargoRequestsTab(),
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
      MaterialPageRoute(
          builder: (context) => LoginScreen()), // Redirect to Login
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Provider.of<LanguageProvider>(context).isSindhi
              ? 'ٽرڪ مالڪ ڊيش بورڊ'
              : 'Truck Owner Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: Provider.of<LanguageProvider>(context).isSindhi
                ? 'لاگ آئوٽ'
                : 'Logout',
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.blue.shade800,
        selectedItemColor: Colors.blueGrey.shade400,
        unselectedItemColor: Colors.blue.shade300,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: Provider.of<LanguageProvider>(context).isSindhi
                ? 'منهنجا ٽرڪ'
                : 'My Trucks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: Provider.of<LanguageProvider>(context).isSindhi
                ? 'ڪارجو بڪ ڪريو'
                : 'Book Cargo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: Provider.of<LanguageProvider>(context).isSindhi
                ? 'جائزا'
                : 'Reviews',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: Provider.of<LanguageProvider>(context).isSindhi
                ? 'نوٽيفڪيشن'
                : 'Notifications',
          ),
        ],
      ),
    );
  }
}
