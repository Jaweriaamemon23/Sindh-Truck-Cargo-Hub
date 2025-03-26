import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void showAddTruckDialog(BuildContext context) {
  TextEditingController truckNumberController = TextEditingController();
  TextEditingController truckTypeController = TextEditingController();
  TextEditingController capacityController = TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Add New Truck"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: truckNumberController,
                decoration: InputDecoration(labelText: "Truck Number"),
                validator: (value) =>
                    value!.isEmpty ? "Please enter a truck number" : null,
              ),
              TextFormField(
                controller: truckTypeController,
                decoration: InputDecoration(labelText: "Truck Type"),
                validator: (value) =>
                    value!.isEmpty ? "Please enter a truck type" : null,
              ),
              TextFormField(
                controller: capacityController,
                decoration: InputDecoration(labelText: "Capacity (tons)"),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return "Please enter a capacity";
                  if (int.tryParse(value) == null) {
                    return "Capacity must be a number";
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await addTruck(
                  context,
                  truckNumberController.text.trim(),
                  truckTypeController.text.trim(),
                  int.parse(capacityController.text.trim()),
                );
                Navigator.pop(context);
              }
            },
            child: Text("Add"),
          ),
        ],
      );
    },
  );
}

Future<void> addTruck(BuildContext context, String truckNumber,
    String truckType, int capacity) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  User? user = auth.currentUser;
  if (user == null) {
    showSnackBar(context, "❌ Error: User is not logged in!");
    return;
  }

  String? userEmail = user.email;
  String? userPhone = user.phoneNumber;

  // 🔹 Fetch user document based on phone or email
  QuerySnapshot userSnapshot = await firestore
      .collection('users')
      .where(userPhone != null ? "phone" : "email",
          isEqualTo: userPhone ?? userEmail)
      .get();

  if (userSnapshot.docs.isEmpty) {
    showSnackBar(context, "❌ Error: No user found in Firestore!");
    return;
  }

  // ✅ Get user document ID
  String userId = userSnapshot.docs.first.id;

  // ✅ Reference the user document
  DocumentReference userDocRef = firestore.collection('users').doc(userId);

  // ✅ Check if any `truckOwner` exists under this user
  QuerySnapshot truckOwnerSnapshot =
      await userDocRef.collection('truckOwners').get();

  if (truckOwnerSnapshot.docs.isEmpty) {
    showSnackBar(context,
        "❌ Error: No truck owner found! Please add a truck owner first.");
    return;
  }

  // ✅ Get the first truckOwner document
  DocumentSnapshot truckOwnerDoc = truckOwnerSnapshot.docs.first;
  String truckOwnerId = truckOwnerDoc.id; // The existing truckOwner ID

  // ✅ Reference the `addedTrucks` subcollection inside this existing truckOwner
  CollectionReference addedTrucksRef = userDocRef
      .collection('truckOwners')
      .doc(truckOwnerId) // Using existing truckOwner
      .collection('addedTrucks');

  // ✅ Add the truck to the correct subcollection
  await addedTrucksRef.add({
    'truckNumber': truckNumber,
    'truckType': truckType,
    'capacity': capacity,
    'createdAt': FieldValue.serverTimestamp(),
  });

  showSnackBar(context, "✅ Truck added successfully!");
}

/// 🔹 Helper function to show snack bars
void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: message.startsWith("✅") ? Colors.green : Colors.red,
      duration: Duration(seconds: 3),
    ),
  );
}
