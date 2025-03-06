import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cargo_details.dart'; // Import the Cargo Details Screen

class CargoTransporterDashboard extends StatefulWidget {
  @override
  _CargoTransporterDashboardState createState() =>
      _CargoTransporterDashboardState();
}

class _CargoTransporterDashboardState extends State<CargoTransporterDashboard> {
  int _selectedIndex = 0;

  // Screens for each tab
  final List<Widget> _screens = [
    AvailableCargoScreen(), // ✅ Show Available Cargo Tab
    Center(child: Text('Track Shipment')), // Placeholder for Tracking
    Center(
        child: Text(
            'Send Availability Notifications')), // Placeholder for Notifications
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
        title: Text('Cargo Transporter Dashboard'),
        backgroundColor: Colors.blue.shade900,
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
        selectedItemColor: Colors.white,
        backgroundColor: Colors.blue.shade900,
        unselectedItemColor: Colors.white60,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Available Cargo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_boat),
            label: 'Track Shipment',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Send Notifications',
          ),
        ],
      ),

      // **Floating Action Button for Adding Cargo Details**
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CargoDetailsScreen()),
          );
        },
        child: Icon(Icons.local_shipping, size: 28, color: Colors.white),
        tooltip: 'Add Cargo Details',
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ✅ **Available Cargo Screen - Displays Registered Truck Owners**
// ─────────────────────────────────────────────────────────────
class AvailableCargoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            "Available Truck Owners",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900),
          ),
          SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('userType',
                      isEqualTo: 'Truck Owner') // ✅ Fetch only Truck Owners
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text("No available truck owners found."),
                  );
                }

                var truckOwners = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: truckOwners.length,
                  itemBuilder: (context, index) {
                    var owner = truckOwners[index];
                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.local_shipping,
                            color: Colors.blue.shade900),
                        title: Text(owner['name'],
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Phone: ${owner['phone']}"),
                        trailing: Icon(Icons.arrow_forward_ios,
                            color: Colors.blue.shade900),
                        onTap: () {
                          // You can navigate to a truck owner details page here
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}