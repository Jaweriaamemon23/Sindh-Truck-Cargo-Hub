import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart'; // Required for context.watch
import 'reviews.dart';
import '../providers/language_provider.dart'; // Make sure you import your language provider

class MyCargoScreen extends StatefulWidget {
  @override
  _MyCargoScreenState createState() => _MyCargoScreenState();
}

class _MyCargoScreenState extends State<MyCargoScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CargoReviewSystem _reviewSystem = CargoReviewSystem();

  Stream<QuerySnapshot> getCargoStream() {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.empty();

    return FirebaseFirestore.instance
        .collection('bookings')
        .where('email', isEqualTo: currentUser.email)
        .snapshots();
  }

  void _showTruckOwnerDetails(String status, String acceptedBy) {
    final isSindhi = context.read<LanguageProvider>().isSindhi;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isSindhi ? '$status بابت ڄاڻ' : '$status Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isSindhi
                    ? (status == 'Delivered' ? 'پهچايو ويو :' : 'منظور ڪندڙ :')
                    : (status == 'Delivered'
                        ? 'Delivered by:'
                        : 'Accepted by:'),
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              SelectableText(acceptedBy),
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showTruckOwnerReviews(acceptedBy);
                },
                icon: Icon(Icons.rate_review),
                label: Text(isSindhi ? "نظرثاني ڏسو" : "Show Reviews"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isSindhi ? "بند ڪريو" : "Close"),
            ),
          ],
        );
      },
    );
  }

  void _showTruckOwnerReviews(String truckOwnerEmail) {
    final isSindhi = context.read<LanguageProvider>().isSindhi;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:
              Text(isSindhi ? 'ٽرڪ ڊرائيور جي نظرثاني' : 'Truck Owner Reviews'),
          content: Container(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reviews')
                  .where('truckOwnerEmail', isEqualTo: truckOwnerEmail)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Text(isSindhi
                      ? 'هن ٽرڪ ڊرائيور لاءِ ڪا به نظرثاني نه ملي.'
                      : 'No reviews found for this truck owner.');
                }

                var reviews = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    var review = reviews[index].data() as Map<String, dynamic>;
                    double rating = review['rating']?.toDouble() ?? 0.0;
                    String comment = review['review'] ?? '';
                    Timestamp ts = review['timestamp'];
                    DateTime date = ts.toDate();

                    return ListTile(
                      leading: Icon(Icons.star, color: Colors.amber),
                      title: Text(isSindhi
                          ? "درجه بندي: ${rating.toStringAsFixed(1)}"
                          : "Rating: ${rating.toStringAsFixed(1)}"),
                      subtitle: Text("$comment\n${date.toLocal()}"),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isSindhi ? "بند ڪريو" : "Close"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSindhi = context.watch<LanguageProvider>().isSindhi;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            isSindhi ? "منهنجو ڪارگو" : "My Cargo",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade900,
            ),
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
                      isSindhi
                          ? "توهان اڃا تائين ڪا به ڪارگو درخواست نه ڏني آهي."
                          : "You have not requested any cargo yet.",
                      style:
                          TextStyle(fontSize: 18, color: Colors.blue.shade900),
                    ),
                  );
                }

                var cargoList = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: cargoList.length,
                  itemBuilder: (context, index) {
                    var cargo = cargoList[index].data() as Map<String, dynamic>;

                    String cargoType = cargo['cargoType'] ?? 'Unknown';
                    String startCity = cargo['startCity'] ?? 'Unknown';
                    String endCity = cargo['endCity'] ?? 'Unknown';
                    double weight = (cargo['weight'] != null)
                        ? (cargo['weight'] is String
                            ? double.tryParse(cargo['weight']) ?? 0.0
                            : cargo['weight'].toDouble())
                        : 0.0;
                    String status = cargo['status'] ?? 'Pending';
                    bool isReviewed = cargo['reviewed'] ?? false;
                    String? acceptedBy = cargo['acceptedBy'];

                    Color statusColor = status == 'Booked'
                        ? Colors.orange
                        : (status == 'Accepted'
                            ? Colors.blue
                            : (status == 'Delivered'
                                ? Colors.green
                                : Colors.orange));

                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.inventory,
                                color: Colors.blue.shade900),
                            title: Text(cargoType),
                            subtitle: Text(
                              isSindhi
                                  ? "کان: $startCity ➝ ڏانهن: $endCity\nوزن: ${weight.toString()} ٽن"
                                  : "From: $startCity ➝ To: $endCity\nWeight: ${weight.toString()} tons",
                            ),
                            trailing: acceptedBy != null
                                ? InkWell(
                                    onTap: () {
                                      _showTruckOwnerDetails(
                                          status, acceptedBy);
                                    },
                                    child: Container(
                                      width: 120,
                                      child: Chip(
                                        backgroundColor: statusColor,
                                        label: Text(
                                          isSindhi
                                              ? (status == 'Delivered'
                                                  ? 'پهچايو ويو'
                                                  : status == 'Accepted'
                                                      ? 'قبول ڪيو ويو'
                                                      : 'بڪ ڪيو ويو')
                                              : status,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : SizedBox(
                                    width: 120,
                                    child: Chip(
                                      backgroundColor: statusColor,
                                      label: Text(
                                        isSindhi
                                            ? (status == 'Delivered'
                                                ? 'پهچايو ويو'
                                                : status == 'Accepted'
                                                    ? 'قبول ڪيو ويو'
                                                    : 'بڪ ڪيو ويو')
                                            : status,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 16.0),
                            minVerticalPadding: 8.0,
                            isThreeLine: false,
                            dense: true,
                          ),
                          if (status == 'Delivered' && !isReviewed)
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 8.0, right: 8.0),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    _reviewSystem.showReviewDialog(
                                      context,
                                      cargoList[index].id,
                                      () {
                                        setState(() {});
                                      },
                                    );
                                  },
                                  icon: Icon(Icons.star, color: Colors.amber),
                                  label: Text(isSindhi
                                      ? "نظرثاني ڪريو"
                                      : "Leave a Review"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade800,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          if (status == 'Delivered' && isReviewed)
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 8.0, right: 8.0),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Chip(
                                  label: Text(isSindhi
                                      ? "نظرثاني ڪئي وئي"
                                      : "Reviewed"),
                                  backgroundColor: Colors.grey.shade200,
                                  avatar: Icon(Icons.check_circle,
                                      color: Colors.green),
                                ),
                              ),
                            ),
                        ],
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
