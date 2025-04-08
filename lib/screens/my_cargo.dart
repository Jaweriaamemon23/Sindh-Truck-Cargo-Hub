import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyCargoScreen extends StatefulWidget {
  @override
  _MyCargoScreenState createState() => _MyCargoScreenState();
}

class _MyCargoScreenState extends State<MyCargoScreen> {
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

  void _showReviewDialog(BuildContext context, String bookingId) {
    double rating = 3.0;
    TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Rate Your Experience"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("How was your delivery experience?"),
            SizedBox(height: 10),
            StatefulBuilder(
              builder: (context, setState) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 30,
                    ),
                    onPressed: () {
                      setState(() {
                        rating = index + 1;
                      });
                    },
                  );
                }),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: reviewController,
              decoration: InputDecoration(
                hintText: "Add your comments (optional)",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              // Submit review to Firestore
              _submitReview(bookingId, rating, reviewController.text);
              Navigator.pop(context);
            },
            child: Text("Submit"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }

  void _submitReview(String bookingId, double rating, String comment) {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return;

    // For debugging
    print("⭐ Starting review submission for booking: $bookingId");

    // First get the booking details to determine the truck owner's info
    FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .get()
        .then((bookingDoc) {
      if (!bookingDoc.exists) {
        print("❌ Booking document not found!");
        return;
      }

      var bookingData = bookingDoc.data();
      // Get acceptedBy (truck owner ID) from the booking
      String? acceptedById = bookingData?['acceptedBy'];

      if (acceptedById == null) {
        print("❌ acceptedBy field not found in booking document!");
        return;
      }

      print("✅ Found acceptedBy ID: $acceptedById, now fetching their email");

      // Get truck owner's email from users collection using the acceptedBy ID
     FirebaseFirestore.instance
    .collection('bookings')
    .doc(bookingId)
    .get()
    .then((bookingDoc) {
  if (!bookingDoc.exists) {
    print("❌ Booking document not found!");
    return;
  }

  var bookingData = bookingDoc.data();

  // 🚨 Get the truck owner's email directly from the 'acceptedBy' field
  String? truckOwnerEmail = bookingData?['acceptedBy'];

  if (truckOwnerEmail == null) {
    print("❌ acceptedBy (email) not found in booking document!");
    return;
  }

  print("✅ Found truck owner email: $truckOwnerEmail");

        // Now add the review to Firestore
        FirebaseFirestore.instance.collection('reviews').add({
          'cargoTransporterEmail': currentUser.email,
          'rating': rating,
          'review': comment,
          'timestamp': FieldValue.serverTimestamp(),
          'truckOwnerEmail': truckOwnerEmail,
          'bookingId': bookingId, // Keep for reference
        }).then((_) {
          print("✅ Review document created successfully!");

          // Update booking with review status AND update state
          FirebaseFirestore.instance
              .collection('bookings')
              .doc(bookingId)
              .update({
            'reviewed': true,
          }).then((_) {
            print("✅ Booking marked as reviewed");

            // Force UI refresh
            setState(() {
              // This will trigger a rebuild with updated data
            });

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Thank you for your feedback!"),
                backgroundColor: Colors.green,
              ),
            );
          });
        }).catchError((error) {
          print("❌ Error adding review: $error");
        });
      }).catchError((error) {
        print("❌ Error getting truck owner document: $error");
      });
    }).catchError((error) {
      print("❌ Error retrieving booking document: $error");
    });
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

                    // Check if cargo has been reviewed
                    bool isReviewed = cargo['reviewed'] ?? false;

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
                                "From: $startCity ➝ To: $endCity\nWeight: ${weight.toString()} tons"),
                            trailing: Text(
                              status,
                              style: TextStyle(
                                color: status == 'Booked'
                                    ? Colors.orange
                                    : (status == 'Accepted'
                                        ? Colors.blue
                                        : (status == 'Delivered'
                                            ? Colors.green
                                            : Colors.orange)),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          // Add review button only if status is delivered and not yet reviewed
                          if (status == 'Delivered' && !isReviewed)
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 8.0, right: 8.0),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Show review dialog
                                    _showReviewDialog(
                                        context, cargoList[index].id);
                                  },
                                  icon: Icon(Icons.star, color: Colors.amber),
                                  label: Text("Leave a Review"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade800,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          // Show reviewed badge if the user has already left a review
                          if (status == 'Delivered' && isReviewed)
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 8.0, right: 8.0),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Chip(
                                  label: Text("Reviewed"),
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
