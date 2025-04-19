import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackScreen extends StatelessWidget {
  void showFeedbackDialog(
      BuildContext context, String email, String userName) async {
    final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('truckOwnerEmail', isEqualTo: email)
        .get();

    final reviews = reviewsSnapshot.docs;

    double avgRating = 0;
    if (reviews.isNotEmpty) {
      final total = reviews.fold<double>(
        0.0,
        (sum, doc) => sum + (doc['rating']?.toDouble() ?? 0.0),
      );
      avgRating = total / reviews.length;
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Feedback for $userName'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "⭐ Average Rating: ${avgRating.toStringAsFixed(1)} / 5.0",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Divider(),
              if (reviews.isEmpty)
                Text("No feedback yet.")
              else
                ...reviews.map((doc) {
                  return ListTile(
                    leading:
                        Icon(Icons.person_outline, color: Colors.grey[600]),
                    title: Text(doc['cargoTransporterEmail'] ?? "Anonymous"),
                    subtitle: Text(doc['review'] ?? ""),
                    trailing: Text("⭐ ${doc['rating']}"),
                  );
                }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          )
        ],
      ),
    );
  }

  void confirmAndRemoveUser(BuildContext context, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Remove User"),
        content: Text("Are you sure you want to remove this truck owner?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel")),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text("Remove", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("User removed.")));
    }
  }

  Future<double> getAverageRating(String email) async {
    final reviewsSnapshot = await FirebaseFirestore.instance
        .collection('reviews')
        .where('truckOwnerEmail', isEqualTo: email)
        .get();

    final reviews = reviewsSnapshot.docs;

    if (reviews.isEmpty) return 0.0;

    final total = reviews.fold<double>(
      0.0,
      (sum, doc) => sum + (doc['rating']?.toDouble() ?? 0.0),
    );

    return total / reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Truck Owners"),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('userType', isEqualTo: 'Truck Owner')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No truck owners found."));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final data = user.data() as Map<String, dynamic>;

              final name = data['name'] ?? "Unnamed";
              final email = data['email'] ?? "No email";
              final phone = data['phone'] ?? "";
              final userId = user.id;

              return FutureBuilder<double>(
                future: getAverageRating(email),
                builder: (context, ratingSnapshot) {
                  final rating = ratingSnapshot.data ?? 0.0;
                  final isLowRating = rating < 2.5;

                  return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    margin: EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ),
                              if (isLowRating)
                                Tooltip(
                                  message: "Low rating",
                                  child: Icon(Icons.warning,
                                      color: Colors.redAccent),
                                ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text("Email: $email"),
                          Text("Phone: $phone"),
                          SizedBox(height: 8),
                          Text("⭐ Avg Rating: ${rating.toStringAsFixed(1)}"),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () =>
                                    showFeedbackDialog(context, email, name),
                                icon: Icon(Icons.feedback),
                                label: Text("Feedback"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors
                                      .white, // Ensures icon + ripple effects are white
                                ),
                              ),
                              if (isLowRating)
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      confirmAndRemoveUser(context, userId),
                                  icon: Icon(Icons.delete),
                                  label: Text("Remove"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                  ),
                                ),
                            ],
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
