import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';

class CargoReviewSystem {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Shows the review dialog for the given booking
  void showReviewDialog(
      BuildContext context, String bookingId, Function onReviewSubmitted) {
    double rating = 3.0;
    TextEditingController reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          Provider.of<LanguageProvider>(context).isSindhi
              ? 'پنھنجو تجربو درجابو ڪريو'
              : 'Rate Your Experience',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Provider.of<LanguageProvider>(context).isSindhi
                  ? 'توهان جو ترسيل جو تجربو ڪيئن هو؟'
                  : 'How was your delivery experience?',
            ),
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
                hintText: Provider.of<LanguageProvider>(context).isSindhi
                    ? 'پنھنجو تبصرو داخل ڪريو (اختياري)'
                    : 'Add your comments (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              Provider.of<LanguageProvider>(context).isSindhi
                  ? 'منسوخ ڪريو'
                  : 'Cancel',
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Submit review to Firestore
              submitReview(context, bookingId, rating, reviewController.text,
                  onReviewSubmitted);
              Navigator.pop(context);
            },
            child: Text(
              Provider.of<LanguageProvider>(context).isSindhi
                  ? 'جمع ڪريو'
                  : 'Submit',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }

  /// Submits the review to Firestore
  void submitReview(BuildContext context, String bookingId, double rating,
      String comment, Function onReviewSubmitted) {
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

      print(
          "✅ Found acceptedBy ID: $acceptedById, using it as truckOwnerEmail");

      // Use the acceptedBy value directly as truckOwnerEmail
      String truckOwnerEmail = acceptedById;

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

        // Update booking with review status
        FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .update({
          'reviewed': true,
        }).then((_) {
          print("✅ Booking marked as reviewed");

          // Call the callback to refresh the UI
          onReviewSubmitted();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                Provider.of<LanguageProvider>(context).isSindhi
                    ? 'توهان جي راءِ جي مهرباني!'
                    : 'Thank you for your feedback!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }).catchError((error) {
          print("❌ Error updating booking: $error");
          _showErrorSnackBar(
            context,
            Provider.of<LanguageProvider>(context).isSindhi
                ? 'بوڪنگ کي اپڊيٽ ڪرڻ ۾ غلطي'
                : 'Error updating booking. Please try again.',
          );
        });
      }).catchError((error) {
        print("❌ Error adding review: $error");
        _showErrorSnackBar(
          context,
          Provider.of<LanguageProvider>(context).isSindhi
              ? 'جائزو موڪلڻ ۾ غلطي'
              : 'Error submitting review. Please try again.',
        );
      });
    }).catchError((error) {
      print("❌ Error retrieving booking document: $error");
      _showErrorSnackBar(
        context,
        Provider.of<LanguageProvider>(context).isSindhi
            ? 'بوڪنگ جي تفصيل حاصل ڪرڻ ۾ غلطي'
            : 'Error retrieving booking details. Please try again.',
      );
    });
  }

  /// Helper method to show error messages
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
