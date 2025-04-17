import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    UserManagementScreen(),
    TruckManagementScreen(),
    NotificationsScreen(),
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
        title: Text(
          Provider.of<LanguageProvider>(context, listen: false).isSindhi
              ? 'ايڊمن ڊيش بورڊ'
              : 'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label:
                Provider.of<LanguageProvider>(context, listen: false).isSindhi
                    ? 'استعمال ڪندڙ'
                    : 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label:
                Provider.of<LanguageProvider>(context, listen: false).isSindhi
                    ? 'ٽرڪ'
                    : 'Trucks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label:
                Provider.of<LanguageProvider>(context, listen: false).isSindhi
                    ? 'نوٽيفڪيشن'
                    : 'Notifications',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue.shade900,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

class UserManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildScreen(
      icon: Icons.person,
      title: Provider.of<LanguageProvider>(context, listen: false).isSindhi
          ? 'استعمال ڪندڙن جو انتظام ڪريو'
          : 'Manage Users',
      buttonText: Provider.of<LanguageProvider>(context, listen: false).isSindhi
          ? 'صارف انتظام تائين وڃو'
          : 'Go to User Management',
      onPressed: () {
        // Add navigation logic
      },
    );
  }
}

class TruckManagementScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildScreen(
      icon: Icons.local_shipping,
      title: Provider.of<LanguageProvider>(context, listen: false).isSindhi
          ? 'ٽرڪ جو انتظام ڪريو'
          : 'Manage Trucks',
      buttonText: Provider.of<LanguageProvider>(context, listen: false).isSindhi
          ? 'ٽرڪ انتظام تائين وڃو'
          : 'Go to Truck Management',
      onPressed: () {
        // Add navigation logic
      },
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildScreen(
      icon: Icons.notifications,
      title: Provider.of<LanguageProvider>(context, listen: false).isSindhi
          ? 'نوٽيفڪيشن'
          : 'Notifications',
      buttonText: Provider.of<LanguageProvider>(context, listen: false).isSindhi
          ? 'نوٽيفڪيشن ڏسو'
          : 'View Notifications',
      onPressed: () {
        // Add navigation logic
      },
    );
  }
}

Widget _buildScreen({
  required IconData icon,
  required String title,
  required String buttonText,
  required VoidCallback onPressed,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 80, color: Colors.blue.shade900),
        SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: onPressed,
          child: Text(buttonText),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.blue.shade900,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
}
