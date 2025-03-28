import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cargo_details.dart';

class CargoTransporterDashboard extends StatefulWidget {
  @override
  _CargoTransporterDashboardState createState() =>
      _CargoTransporterDashboardState();
}

class _CargoTransporterDashboardState extends State<CargoTransporterDashboard> {
  int _selectedIndex = 0;

  // Screens for each tab
  final List<Widget> _screens = [
    MyCargoScreen(), // ✅ My Cargo Tab
    AvailableTrucksScreen(), // ✅ Available Trucks Tab
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
            icon: Icon(Icons.inbox),
            label: 'My Cargo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Available Trucks',
          ),
        ],
      ),

      // Floating Action Button for Adding Cargo Details
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade900,
        onPressed: () {
          // Navigate to the Cargo Details Input screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CargoDetailsScreen()),
          );
        },
        child: Icon(Icons.add, size: 28, color: Colors.white),
        tooltip: 'Add Cargo',
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ✅ **My Cargo Screen - Displays Cargo Added by Transporter**
// ─────────────────────────────────────────────────────────────
class MyCargoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            "My Cargo",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900),
          ),
          SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cargoRequests') // ✅ Fetch Transporter's Cargo
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text("No cargo added yet."),
                  );
                }

                var cargoList = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: cargoList.length,
                  itemBuilder: (context, index) {
                    var cargo = cargoList[index];
                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Icon(Icons.inventory, color: Colors.blue.shade900),
                        title: Text(cargo['cargoType'],
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("From: ${cargo['startCity']} → To: ${cargo['endCity']}"),
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.blue.shade900),
                        onTap: () {
                          // Navigate to Cargo Details Page if needed
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

// ─────────────────────────────────────────────────────────────
// ✅ **Available Trucks Screen - Lists Available Truck Owners**
// ─────────────────────────────────────────────────────────────
class AvailableTrucksScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            "Available Trucks",
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
                  .where('userType', isEqualTo: 'Truck Owner') // ✅ Fetch Truck Owners
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text("No available trucks found."),
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
                        leading: Icon(Icons.local_shipping, color: Colors.blue.shade900),
                        title: Text(owner['name'],
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Phone: ${owner['phone']}"),
                        trailing: Icon(Icons.arrow_forward_ios, color: Colors.blue.shade900),
                        onTap: () {
                          // Navigate to truck details page if needed
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