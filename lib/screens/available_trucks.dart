import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AvailableTrucksScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getTrucksStream() {
    return FirebaseFirestore.instance
        .collection('trucks')
        .where('status', isEqualTo: 'available')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                "No available trucks.",
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
                  title: Text(truck['truckNumber'] ?? 'Unknown'),
                  subtitle: Text(
                      "Type: ${truck['truckType']} | Capacity: ${truck['capacity']} tons"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
