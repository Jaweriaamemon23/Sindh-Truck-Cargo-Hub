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

  Future<String?> getPhoneNumberFromEmail(String email) async {
    try {
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isNotEmpty) {
        return userQuery.docs.first.id;
      } else {
        print("❌ ERROR: No user found with email: $email");
        return null;
      }
    } catch (e) {
      print("❌ ERROR fetching phone number: $e");
      return null;
    }
  }

  Stream<QuerySnapshot> getTrucksStream() async* {
    User? currentUser = _auth.currentUser;

    if (currentUser == null || currentUser.email == null) {
      print("❌ ERROR: User not logged in or email missing!");
      yield* Stream.empty();
      return;
    }

    String email = currentUser.email!;
    String? phoneNumber = await getPhoneNumberFromEmail(email);
    if (phoneNumber == null) {
      print("❌ ERROR: Could not find phone number for this email!");
      yield* Stream.empty();
      return;
    }

    yield* FirebaseFirestore.instance
        .collection('users')
        .doc(phoneNumber)
        .collection('truckOwners')
        .snapshots()
        .asyncExpand((truckOwnerSnapshot) async* {
      if (truckOwnerSnapshot.docs.isEmpty) {
        yield* Stream.empty();
        return;
      }

      String truckOwnerId = truckOwnerSnapshot.docs.first.id;

      yield* FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .collection('truckOwners')
          .doc(truckOwnerId)
          .collection('addedTrucks')
          .snapshots();
    });
  }

  /// 🗑 **Remove Truck Function**
  Future<void> removeTruck(String truckId) async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null || currentUser.email == null) return;

    String? phoneNumber = await getPhoneNumberFromEmail(currentUser.email!);
    if (phoneNumber == null) return;

    try {
      var truckOwnerQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(phoneNumber)
          .collection('truckOwners')
          .get();

      if (truckOwnerQuery.docs.isNotEmpty) {
        String truckOwnerId = truckOwnerQuery.docs.first.id;

        await FirebaseFirestore.instance
            .collection('users')
            .doc(phoneNumber)
            .collection('truckOwners')
            .doc(truckOwnerId)
            .collection('addedTrucks')
            .doc(truckId)
            .delete();

        print("✅ Truck removed successfully!");
      }
    } catch (e) {
      print("❌ ERROR removing truck: $e");
    }
  }

  /// ⚠️ **Delete Confirmation Dialog**
  Future<bool> showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Delete Truck"),
            content: Text("Are you sure you want to delete this truck?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Delete", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
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
              String truckId = truck.id;

              return Card(
                elevation: 3,
                margin: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading:
                      Icon(Icons.local_shipping, color: Colors.blue.shade900),
                  title: Text(truck['truckNumber'] ?? 'Unknown'),
                  subtitle: Text(
                      "Type: ${truck['truckType']} | Capacity: ${truck['capacity']} tons"),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      bool confirm =
                          await showDeleteConfirmationDialog(context);
                      if (confirm) await removeTruck(truckId);
                    },
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
