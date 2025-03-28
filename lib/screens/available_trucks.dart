import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
