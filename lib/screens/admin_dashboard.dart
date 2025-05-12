import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:sindh_truck_cargo_hub/screens/available_user.dart';
import 'package:sindh_truck_cargo_hub/screens/feedback.dart';
import 'package:sindh_truck_cargo_hub/screens/reports_screen.dart';
import 'package:sindh_truck_cargo_hub/screens/login_screen.dart';
import 'package:sindh_truck_cargo_hub/screens/admin_graphs_screen.dart'; // Ensure this import is added
import '../providers/language_provider.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    ReportsScreen(),
    AvailableUsersScreen(),
    FeedbackScreen(),
    AdminGraphsScreen(), // Add this line for the new graph screen
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSindhi ? 'ايڊمن ڊيش بورڊ' : 'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
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
        selectedItemColor: Colors.white, // Color of the selected item
        unselectedItemColor: Colors.white70, // Color of the unselected items
        backgroundColor: Colors.blue.shade800, // Background color of the navbar
        type: BottomNavigationBarType
            .fixed, // Fixed type to handle more than 3 items
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: isSindhi ? ' رپورٽ' : 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: isSindhi ? 'استعمال ڪندڙ' : 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.feedback),
            label: isSindhi ? 'موٽ' : 'Feedback',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: isSindhi ? 'گراف' : 'Graphs',
          ),
        ],
      ),
    );
  }
}
