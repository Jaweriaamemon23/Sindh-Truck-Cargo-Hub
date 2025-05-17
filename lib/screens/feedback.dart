import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackScreen extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Low Rated Truck Owners",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
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

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _filterLowRatedUsers(users),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              final lowRatedUsers = snapshot.data!;

              if (lowRatedUsers.isEmpty) {
                return Center(child: Text("No low-rated truck owners found."));
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: lowRatedUsers.length,
                itemBuilder: (context, index) {
                  final user = lowRatedUsers[index];
                  return _buildUserCard(context, user);
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _filterLowRatedUsers(
      List<QueryDocumentSnapshot> users) async {
    List<Map<String, dynamic>> filtered = [];

    for (var user in users) {
      final data = user.data() as Map<String, dynamic>;
      final email = data['email'] ?? '';
      final rating = await getAverageRating(email);

      if (rating < 2.5 && rating > 0.0) {
        filtered.add({...data, 'id': user.id, 'rating': rating});
      }
    }

    return filtered;
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    final name = user['name'] ?? "Unnamed";
    final email = user['email'] ?? "No email";
    final phone = user['phone'] ?? "";
    final userId = user['id'];
    final rating = user['rating'] ?? 0.0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                Icon(Icons.warning, color: Colors.redAccent),
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
                  onPressed: () => showFeedbackDialog(context, email, name),
                  icon: Icon(Icons.feedback_outlined, color: Colors.white),
                  label:
                      Text("Feedback", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => confirmAndRemoveUser(context, userId),
                  icon: Icon(Icons.delete, color: Colors.white),
                  label: Text("Remove", style: TextStyle(color: Colors.white)),
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
  }
}