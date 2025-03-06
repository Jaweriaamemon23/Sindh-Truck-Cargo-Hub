import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TruckOwnerDashboard extends StatefulWidget {
  @override
  _TruckOwnerDashboardState createState() => _TruckOwnerDashboardState();
}

class _TruckOwnerDashboardState extends State<TruckOwnerDashboard> {
  int _selectedIndex = 0;

  // List of screens for each tab
  final List<Widget> _screens = [
    AvailableTrucksScreen(), // My Trucks screen
    Center(child: Text('Manage Vehicles', style: TextStyle(fontSize: 20))),
    Center(child: Text('Book Cargo', style: TextStyle(fontSize: 20))),
    Center(child: Text('View Notifications', style: TextStyle(fontSize: 20))),
  ];

  // Function to handle tab index change
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade100,
              Colors.blue.shade300,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _screens[_selectedIndex],
      ),
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Trucks',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        actions: [
          ElevatedButton(
            onPressed: () {
              _showAddTruckDialog(
                  context); // Call the function to show the add truck dialog
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800, // Match AppBar color
              padding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8), // Button padding
            ),
            child: Text(
              "Add Truck",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: Colors.blue.shade50,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('trucks')
              .where('ownerId',
                  isEqualTo: 'currentUserId') // Replace with actual owner ID
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  "No trucks registered yet.",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blue.shade900,
                  ),
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
                      truck['truckNumber'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      "Type: ${truck['truckType']} | Capacity: ${truck['capacity']} tons",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deleteTruck(truck.id);
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Function to show a dialog for adding a new truck
  void _showAddTruckDialog(BuildContext context) {
    TextEditingController truckNumberController = TextEditingController();
    TextEditingController truckTypeController = TextEditingController();
    TextEditingController capacityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            "Add New Truck",
            style: TextStyle(
              color: Colors.blue.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: truckNumberController,
                decoration: InputDecoration(
                  labelText: "Truck Number",
                  labelStyle: TextStyle(color: Colors.blue.shade900),
                ),
              ),
              TextField(
                controller: truckTypeController,
                decoration: InputDecoration(
                  labelText: "Truck Type",
                  labelStyle: TextStyle(color: Colors.blue.shade900),
                ),
              ),
              TextField(
                controller: capacityController,
                decoration: InputDecoration(
                  labelText: "Capacity (tons)",
                  labelStyle: TextStyle(color: Colors.blue.shade900),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "Cancel",
                style: TextStyle(color: Colors.blue.shade900),
              ),
            ),
            TextButton(
              onPressed: () {
                _addTruck(
                  truckNumberController.text,
                  truckTypeController.text,
                  int.parse(capacityController.text),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Truck added successfully!"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text(
                "Add",
                style: TextStyle(color: Colors.blue.shade900),
              ),
            ),
          ],
        );
      },
    );
  }

  // Function to add a new truck to Firestore
  void _addTruck(String truckNumber, String truckType, int capacity) async {
    await FirebaseFirestore.instance.collection('trucks').add({
      'truckNumber': truckNumber,
      'truckType': truckType,
      'capacity': capacity,
      'ownerId': 'currentUserId', // Replace with actual owner ID
    });
  }

  // Function to delete a truck from Firestore
  void _deleteTruck(String truckId) async {
    await FirebaseFirestore.instance.collection('trucks').doc(truckId).delete();
  }
}
