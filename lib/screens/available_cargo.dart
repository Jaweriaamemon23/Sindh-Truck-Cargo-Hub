import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AvailableCargoScreen extends StatefulWidget {
  @override
  _AvailableCargoScreenState createState() => _AvailableCargoScreenState();
}

class _AvailableCargoScreenState extends State<AvailableCargoScreen> {
  String _searchQuery = "";

  /// ✅ **Fetch All Truck Owners Who Are Email Verified**
  Stream<QuerySnapshot> _getTruckOwners() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('userType', isEqualTo: 'Truck Owner')
        .where('emailVerified', isEqualTo: true) // ✅ Only Verified Users
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("🚚 Available Truck Owners"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getTruckOwners(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var truckOwners = snapshot.data!.docs
                    .where((doc) => doc['name']
                        .toString()
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()))
                    .toList();

                if (truckOwners.isEmpty) {
                  return Center(
                      child: Text("No available truck owners at the moment.",
                          style: TextStyle(color: Colors.grey)));
                }

                return ListView.builder(
                  itemCount: truckOwners.length,
                  itemBuilder: (context, index) {
                    var data =
                        truckOwners[index].data() as Map<String, dynamic>;
                    return _buildTruckOwnerCard(data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 🔍 **Search Bar**
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          labelText: "Search by name...",
          prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// 🎨 **Truck Owner Card UI**
  Widget _buildTruckOwnerCard(Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.person, color: Colors.blueAccent),
        title: Text(data['name'] ?? "No Name",
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📞 Phone: ${data['phone'] ?? 'N/A'}"),
            Text("🚛 Vehicle: ${data['vehicleType'] ?? 'Unknown'}"),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _showContactDialog(data),
          child: Text("Contact"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }

  /// 📞 **Contact Dialog**
  void _showContactDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Contact ${data['name']}"),
        content: Text(
            "📞 Phone: ${data['phone']}\n🚛 Vehicle: ${data['vehicleType'] ?? 'N/A'}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }
}