import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FilteredUsersScreen extends StatelessWidget {
  final String userType;

  FilteredUsersScreen({required this.userType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$userType Users'),
        backgroundColor: Colors.blue.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('userType', isEqualTo: userType)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs;

          if (users.isEmpty) {
            return Center(child: Text("No $userType users found."));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text(user['name'] ?? 'No Name'),
                  subtitle: Text(user['email'] ?? 'No Email'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
