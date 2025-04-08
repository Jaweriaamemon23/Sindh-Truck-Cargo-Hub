import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TruckOwnerReviewsScreen extends StatelessWidget {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      print("🚫 User not logged in");
      return Scaffold(
        appBar: AppBar(title: Text("My Reviews")),
        body: Center(child: Text("User not logged in.")),
      );
    }

    print("👤 Logged in as: ${currentUser!.email}");

    return Scaffold(
      appBar: AppBar(
        title: Text("My Reviews", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('truckOwnerEmail', isEqualTo: currentUser!.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print("❌ Error: ${snapshot.error}");
            return Center(child: Text("❌ Error loading reviews."));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            print("📧 Current Truck Owner Email: ${currentUser!.email}");

            print("⏳ Waiting for data...");
            return Center(child: CircularProgressIndicator());
          }

          final reviews = snapshot.data?.docs ?? [];
          print("📦 Reviews fetched: ${reviews.length}");

          if (reviews.isEmpty) {
            return Center(child: Text("No reviews yet."));
          }

          double totalRating = 0;
          for (var doc in reviews) {
            try {
              final data = doc.data() as Map<String, dynamic>;
              final rating = (data['rating'] ?? 0).toDouble();
              totalRating += rating;
              print("⭐ Review from ${data['cargoTransporterEmail']}: $rating");
            } catch (e) {
              print("⚠️ Error reading review: $e");
            }
          }

          double avgRating = totalRating / reviews.length;
          print("📊 Average Rating: $avgRating");

          return Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.blue.shade50,
                child: Column(
                  children: [
                    Text(
                      "Average Rating",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < avgRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.orange,
                          size: 30,
                        );
                      }),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "${avgRating.toStringAsFixed(1)} / 5.0 (${reviews.length} review${reviews.length > 1 ? 's' : ''})",
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    try {
                      var data = reviews[index].data() as Map<String, dynamic>;

                      final from = data['cargoTransporterEmail'] ?? 'Unknown';
                      final rating = data['rating'] ?? 0;
                      final comment = data['review'] ?? '';
                      final timestamp = data['timestamp'] != null
                          ? (data['timestamp'] as Timestamp).toDate()
                          : null;

                      print("📄 Review $index -> From: $from, Rating: $rating");

                      return Card(
                        margin: EdgeInsets.symmetric(vertical: 8),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Icon(Icons.person, color: Colors.blue),
                          title: Text("From: $from"),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: List.generate(
                                  5,
                                  (starIndex) => Icon(
                                    starIndex < rating
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                ),
                              ),
                              if (comment.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text("“$comment”"),
                                ),
                              if (timestamp != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    "Reviewed on: ${timestamp.day}/${timestamp.month}/${timestamp.year}",
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    } catch (e) {
                      print("⚠️ Error rendering review card: $e");
                      return SizedBox.shrink();
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
