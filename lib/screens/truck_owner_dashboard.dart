import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_truck_dialog.dart';

class TruckOwnerDashboard extends StatefulWidget {
  @override
  _TruckOwnerDashboardState createState() => _TruckOwnerDashboardState();
}

class _TruckOwnerDashboardState extends State<TruckOwnerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    AvailableTrucksScreen(),
    Center(child: Text('Manage Vehicles', style: TextStyle(fontSize: 20))),
    Center(child: Text('Book Cargo', style: TextStyle(fontSize: 20))),
    Center(child: Text('View Notifications', style: TextStyle(fontSize: 20))),
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
          'Truck Owner Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.blue.shade800,
        selectedItemColor: Colors.blueGrey.shade400,
        unselectedItemColor: Colors.blue.shade300,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'My Trucks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Manage Vehicles',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Book Cargo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
        ],
      ),
    );
  }
}

class AvailableTrucksScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 Fetch trucks from nested subcollection
  Stream<QuerySnapshot> getTrucksStream() {
    User? currentUser = _auth.currentUser;

    if (currentUser == null || currentUser.email == null) {
      print("❌ ERROR: User is not logged in or email missing!");
      return const Stream.empty();
    }

    String email = currentUser.email!;
    print("📌 Fetching trucks for email: $email");

    return FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .collection('truckOwners')
        .doc(email)
        .collection('addedTrucks')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    String? userEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Trucks',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
        actions: [
          ElevatedButton(
            onPressed: () {
              if (userEmail != null) {
                showAddTruckDialog(context);
              } else {
                print("❌ ERROR: User email not found!");
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              "Add Truck",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getTrucksStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("❌ Error loading trucks!"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No trucks registered yet.",
                style: TextStyle(fontSize: 18, color: Colors.blue.shade900),
              ),
            );
          }

          var trucks = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: trucks.length,
            itemBuilder: (context, index) {
              var truck = trucks[index];

              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading:
                      Icon(Icons.local_shipping, color: Colors.blue.shade900),
                  title: Text(
                    truck['truckNumber'] ?? 'Unknown',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    "Type: ${truck['truckType'] ?? 'N/A'} | Capacity: ${truck['capacity'] ?? 'N/A'} tons",
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
