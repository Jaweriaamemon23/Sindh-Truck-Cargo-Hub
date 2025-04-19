import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart'; // Import your LanguageProvider here

class AvailableTrucksScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isSindhi = Provider.of<LanguageProvider>(context).isSindhi;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            isSindhi ? "دستياب ٽرڪ" : "Available Trucks",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(height: 8), // spacing under AppBar
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('userType', isEqualTo: 'Truck Owner')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text(
                        isSindhi
                            ? "ڪو به دستياب ٽرڪ نه آهي."
                            : "No available trucks found.",
                      ),
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
                          title: Text(
                            owner['name'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${isSindhi ? 'فون:' : 'Phone:'} ${owner['phone']}",
                          ),
                          trailing: Icon(Icons.arrow_forward_ios,
                              color: Colors.blue.shade900),
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
      ),
    );
  }
}
