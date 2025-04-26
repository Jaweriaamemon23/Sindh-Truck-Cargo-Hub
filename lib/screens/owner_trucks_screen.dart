import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OwnerTrucksScreen extends StatelessWidget {
  final String ownerPhoneNumber; // Pass phone number of owner

  const OwnerTrucksScreen({required this.ownerPhoneNumber, Key? key})
      : super(key: key);

  Stream<QuerySnapshot> getOwnerTrucksStream() async* {
    // Fetch truckOwners collection first
    var truckOwnerSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(ownerPhoneNumber)
        .collection('truckOwners')
        .get();

    if (truckOwnerSnapshot.docs.isEmpty) {
      yield* Stream.empty();
      return;
    }

    String truckOwnerId = truckOwnerSnapshot.docs.first.id;

    yield* FirebaseFirestore.instance
        .collection('users')
        .doc(ownerPhoneNumber)
        .collection('truckOwners')
        .doc(truckOwnerId)
        .collection('addedTrucks')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Owner\'s Trucks'),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
        ),
        backgroundColor: Colors.blue.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getOwnerTrucksStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("❌ Error loading trucks!"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No trucks found for this owner."));
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
                  title: Text(truck['truckNumber'] ?? 'Unknown Truck'),
                  subtitle: Text(
                    "Type: ${truck['truckType'] ?? 'N/A'} | Capacity: ${truck['capacity'] ?? 'N/A'} tons",
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
