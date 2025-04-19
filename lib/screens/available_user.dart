import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvailableUsersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Available Users"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 4,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No users found."));
          }

          final users = snapshot.data!.docs.where((doc) {
            if (doc.id == '03333139670') return false;
            final data = doc.data() as Map<String, dynamic>;
            return data.containsKey('name') &&
                data.containsKey('email') &&
                data.containsKey('phone') &&
                data.containsKey('userType');
          }).toList();

          if (users.isEmpty) {
            return Center(child: Text("No users available to display."));
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person,
                              color: Colors.blueAccent, size: 28),
                          SizedBox(width: 8),
                          Text(
                            data['name'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 20, thickness: 1),
                      Row(
                        children: [
                          Icon(Icons.email, size: 20, color: Colors.grey[700]),
                          SizedBox(width: 8),
                          Expanded(
                              child: Text(data['email'],
                                  style: TextStyle(fontSize: 14))),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 20, color: Colors.grey[700]),
                          SizedBox(width: 8),
                          Text(data['phone'], style: TextStyle(fontSize: 14)),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.badge, size: 20, color: Colors.grey[700]),
                          SizedBox(width: 8),
                          Text("User Type: ${data['userType']}",
                              style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ],
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
