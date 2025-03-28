import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyCargoScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot> getCargoStream() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('cargoRequests')
        .where('addedBy', isEqualTo: currentUser.uid)
        .snapshots();
  }

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
              stream: getCargoStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "No cargo added yet.",
                      style: TextStyle(fontSize: 18, color: Colors.blue.shade900),
                    ),
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
                        title: Text(cargo['cargoType'] ?? 'Unknown'),
                        subtitle: Text(
                            "From: ${cargo['startCity']} ➝ To: ${cargo['endCity']}\nWeight: ${cargo['weight']} tons"),
                        trailing: Text(
                          cargo['status'] ?? 'Pending',
                          style: TextStyle(
                            color: cargo['status'] == 'Booked' ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
