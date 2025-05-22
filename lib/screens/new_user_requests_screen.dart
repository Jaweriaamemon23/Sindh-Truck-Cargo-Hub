import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewUserRequestsScreen extends StatelessWidget {
  const NewUserRequestsScreen({super.key});

  Future<void> approveUser(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'verified': true,
    });
  }

  Future<void> rejectUser(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).delete();
  }

  void showUserInfoDialog(
      BuildContext context, Map<String, dynamic> userData, String userId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('User Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Name: ${userData['name']}"),
            Text("Email: ${userData['email']}"),
            Text("Phone: ${userData['phone']}"),
            Text("User Type: ${userData['userType']}"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await approveUser(userId);
              Navigator.pop(context);
            },
            child: Text('Approve'),
          ),
          TextButton(
            onPressed: () async {
              await rejectUser(userId);
              Navigator.pop(context);
            },
            child: Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New User Requests',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('verified', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return Center(child: Text('No new user requests.'));

          final newUsers = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: newUsers.length,
            itemBuilder: (context, index) {
              var user = newUsers[index];
              var userData = user.data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Icon(Icons.person, color: Colors.blue.shade700),
                  title: Text(userData['name']),
                  subtitle: Text(userData['email']),
                  trailing: Icon(Icons.info_outline),
                  onTap: () => showUserInfoDialog(context, userData, user.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
