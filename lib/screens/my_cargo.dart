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

    // Debugging: Print the current user's email to see if it's correct
    print("Current user's email: ${currentUser.email}");

    return FirebaseFirestore.instance
        .collection('bookings') // Correct collection name is 'bookings'
        .where('email',
            isEqualTo: currentUser.email) // Use 'email' field to filter
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
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
              stream:
                  getCargoStream(), // Get the stream of cargo requests for the user
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      "You have not requested any cargo yet.",
                      style:
                          TextStyle(fontSize: 18, color: Colors.blue.shade900),
                    ),
                  );
                }

                var cargoList = snapshot.data!.docs;

                // Log to inspect the document data
                print(
                    "Fetched cargo data: ${cargoList.map((doc) => doc.data()).toList()}");

                return ListView.builder(
                  itemCount: cargoList.length,
                  itemBuilder: (context, index) {
                    var cargo = cargoList[index].data() as Map<String, dynamic>;

                    // Log to see if all fields are properly available
                    print("Cargo Document $index: $cargo");

                    // Safely access the fields with default values
                    String cargoType = cargo['cargoType'] ?? 'Unknown';
                    String startCity = cargo['startCity'] ?? 'Unknown';
                    String endCity = cargo['endCity'] ?? 'Unknown';

                    // Safely handle the 'weight' field by checking if it's null
                    double weight = (cargo['weight'] != null)
                        ? (cargo['weight'] is String
                            ? double.tryParse(cargo['weight']) ?? 0.0
                            : cargo['weight'].toDouble())
                        : 0.0;

                    // Check if 'status' field exists, otherwise use default value
                    String status = cargo['status'] ?? 'Pending';

                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading:
                            Icon(Icons.inventory, color: Colors.blue.shade900),
                        title: Text(cargoType),
                        subtitle: Text(
                            "From: $startCity ➝ To: $endCity\nWeight: ${weight.toString()} tons"),
                        trailing: Text(
                          status,
                          style: TextStyle(
                            color: status == 'Booked'
                                ? Colors.green
                                : Colors.orange,
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
