import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class AvailableCargoScreen extends StatefulWidget {
  @override
  _AvailableCargoScreenState createState() => _AvailableCargoScreenState();
}

class _AvailableCargoScreenState extends State<AvailableCargoScreen> {
  String _searchQuery = "";

  /// ✅ **Fetch Available Cargo Requests**
  Stream<QuerySnapshot> _getAvailableCargo() {
    return FirebaseFirestore.instance.collection('bookings').snapshots();
  }

  /// ✅ **Accept Cargo Request**
  Future<void> _acceptCargo(String cargoId, Map<String, dynamic> cargoData) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    String truckOwnerId = currentUser.uid;

    try {
      // ✅ 1. Add cargo request under the Truck Owner's accepted bookings
      await FirebaseFirestore.instance
          .collection('users')
          .doc(truckOwnerId)
          .collection('acceptedCargo')
          .doc(cargoId)
          .set(cargoData);

      // ✅ 2. Update cargo request status
      await FirebaseFirestore.instance.collection('bookings').doc(cargoId).update({
        'status': 'Accepted',
        'acceptedBy': truckOwnerId,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          Provider.of<LanguageProvider>(context, listen: false).isSindhi
              ? "ڪارگو ڪاميابي سان قبول ڪيو!"
              : "Cargo Accepted Successfully!",
        ),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      print("❌ Error accepting cargo: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          Provider.of<LanguageProvider>(context, listen: false).isSindhi
              ? "ڪارگو قبول ڪرڻ ۾ غلطي آهي. ٻيهر ڪوشش ڪريو."
              : "Error accepting cargo. Try again.",
        ),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          Provider.of<LanguageProvider>(context, listen: false).isSindhi
              ? 'دستياب ڪارگو'
              : 'Available Cargo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getAvailableCargo(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                var cargoList = snapshot.data!.docs.where((doc) =>
                    doc['cargoType']
                        .toString()
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()));

                if (cargoList.isEmpty) {
                  return Center(
                      child: Text(
                    Provider.of<LanguageProvider>(context, listen: false).isSindhi
                        ? "ڪو به موجود ڪارگو درخواست ناهي."
                        : "No available cargo requests.",
                    style: TextStyle(color: Colors.grey),
                  ));
                }

                return ListView.builder(
                  itemCount: cargoList.length,
                  itemBuilder: (context, index) {
                    var cargo = cargoList.elementAt(index);
                    var cargoData = cargo.data() as Map<String, dynamic>;
                    return _buildCargoCard(cargo.id, cargoData);
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
          labelText: Provider.of<LanguageProvider>(context, listen: false).isSindhi
              ? "ڪارگو جي قسم سان ڳوليو..."
              : "Search by cargo type...",
          prefixIcon: Icon(Icons.search, color: Colors.blueAccent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// 🎨 **Cargo Card UI**
  Widget _buildCargoCard(String cargoId, Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(Icons.inventory, color: Colors.blueAccent),
        title: Text(
          "${data['cargoType'] ?? (Provider.of<LanguageProvider>(context, listen: false).isSindhi ? "نامعلوم" : "Unknown")}",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "📍 ${Provider.of<LanguageProvider>(context, listen: false).isSindhi ? 'کان:' : 'From:'} ${data['startCity'] ?? 'N/A'} → ${data['endCity'] ?? 'N/A'}",
            ),
            Text(
              "⚖️ ${Provider.of<LanguageProvider>(context, listen: false).isSindhi ? 'وزن:' : 'Weight:'} ${data['weight'] ?? '0'} ${Provider.of<LanguageProvider>(context, listen: false).isSindhi ? 'ٽن' : 'tons'}",
            ),
            Text(
              "📏 ${Provider.of<LanguageProvider>(context, listen: false).isSindhi ? 'فاصلو:' : 'Distance:'} ${data['distance'] ?? '0'} ${Provider.of<LanguageProvider>(context, listen: false).isSindhi ? 'ڪم' : 'km'}",
            ),
            Text(
              "💰 ${Provider.of<LanguageProvider>(context, listen: false).isSindhi ? 'قيمت:' : 'Price:'} ${data['price'] ?? 0} PKR",
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _acceptCargo(cargoId, data),
          child: Text(
            Provider.of<LanguageProvider>(context, listen: false).isSindhi
                ? 'قبول ڪريو'
                : 'Accept',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }
}
