import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sindh_truck_cargo_hub/screens/truck_owner_reviews.dart';
import 'book_cargo.dart';
import 'my_trucks.dart';
import 'login_screen.dart';
import 'cargo_requests_tab.dart';
import 'package:provider/provider.dart';
import 'package:sindh_truck_cargo_hub/providers/language_provider.dart';

class TruckOwnerDashboard extends StatefulWidget {
  @override
  _TruckOwnerDashboardState createState() => _TruckOwnerDashboardState();
}

class _TruckOwnerDashboardState extends State<TruckOwnerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    MyTrucksScreen(),
    BookCargoScreen(),
    TruckOwnerReviewsScreen(),
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
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSindhi = Provider.of<LanguageProvider>(context).isSindhi;
    final appBarColor = Colors.blue.shade800;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSindhi ? 'ٽرڪ مالڪ ڊيش بورڊ' : 'Truck Owner Dashboard',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: appBarColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: isSindhi ? 'لاگ آئوٽ' : 'Logout',
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.language, color: Colors.white),
            tooltip: isSindhi ? 'ٻولي مٽايو' : 'Change Language',
            onSelected: (value) {
              Provider.of<LanguageProvider>(context, listen: false)
                  .toggleLanguage();
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(value: 'Sindhi', child: Text('Sindhi')),
                PopupMenuItem(value: 'English', child: Text('English')),
              ];
            },
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: appBarColor, // Matching AppBar color
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white60,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.local_shipping),
            label: isSindhi ? 'منهنجا ٽرڪ' : 'My Trucks',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.book),
            label: isSindhi ? 'ڪارجو بڪ ڪريو' : 'Book Cargo',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.star),
            label: isSindhi ? 'جائزا' : 'Reviews',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.notifications),
            label: isSindhi ? 'نوٽيفڪيشن' : 'Notifications',
          ),
        ],
      ),
    );
  }
}
