import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvailableUsersScreen extends StatefulWidget {
  @override
  _AvailableUsersScreenState createState() => _AvailableUsersScreenState();
}

class _AvailableUsersScreenState extends State<AvailableUsersScreen> {
  String _userTypeFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Available Users", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Column(
        children: [
          // 🔽 Dropdown for user type filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text("Filter by User Type:",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(width: 12),
                DropdownButton<String>(
                  value: _userTypeFilter,
                  onChanged: (newValue) {
                    setState(() {
                      _userTypeFilter = newValue!;
                    });
                  },
                  items: <String>[
                    'All',
                    'Business Owner',
                    'Truck Owner',
                    'Cargo Transporter'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // 🔽 Users list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('verified', isEqualTo: true) // ✅ Only verified users
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No users found."));
                }

                final filteredUsers = snapshot.data!.docs.where((doc) {
                  if (doc.id == '03333139670') return false;

                  final data = doc.data() as Map<String, dynamic>;

                  // Exclude users without 'userType', with 'Admin' type, or specific email
                  if (!data.containsKey('userType') ||
                      data['userType'] == 'Admin') return false;
                  if (data['email'] == 'sindhtruckcargohub@gmail.com')
                    return false;

                  // Apply user type filter
                  if (_userTypeFilter == 'All') return true;

                  return data['userType'] == _userTypeFilter;
                }).toList();

                if (filteredUsers.isEmpty) {
                  return Center(child: Text("No users for this filter."));
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
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
                                Icon(Icons.email,
                                    size: 20, color: Colors.grey[700]),
                                SizedBox(width: 8),
                                Expanded(
                                    child: Text(data['email'],
                                        style: TextStyle(fontSize: 14))),
                              ],
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.phone,
                                    size: 20, color: Colors.grey[700]),
                                SizedBox(width: 8),
                                Text(data['phone'],
                                    style: TextStyle(fontSize: 14)),
                              ],
                            ),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.badge,
                                    size: 20, color: Colors.grey[700]),
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
          ),
        ],
      ),
    );
  }
}
