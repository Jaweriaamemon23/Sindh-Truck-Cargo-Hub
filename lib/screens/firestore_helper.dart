import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// **🔥 Registers a new user in FirebaseAuth & Firestore**
  Future<String?> registerUser({
    required String name,
    required String email,
    required String phone,
    required String userType,
    required String password,
  }) async {
    try {
      // ✅ Create user in Firebase Authentication
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String userId = userCredential.user!.uid; // ✅ Firebase User ID

      // ✅ Store user data in Firestore
      await _firestore.collection('users').doc(userId).set({
        'userId': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userId; // ✅ Return userId for navigation
    } catch (e) {
      print("🔥 Registration error: $e");
      return null;
    }
  }

  /// **✅ Logs in user with Firebase Authentication**
  Future<bool> loginUser(
      {required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true; // ✅ Login successful
    } catch (e) {
      print("🔥 Login error: $e");
      return false; // ❌ Login failed
    }
  }

  /// **📌 Logs out the user**
  Future<void> logoutUser() async {
    await _auth.signOut();
    print("✅ User logged out successfully");
  }

  // ─────────────────────────────────────────────────────────────
  // ✅  Function to create Truck Owner Data
  Future<void> createTruckOwnerData(
      String userId, Map<String, dynamic> truckData) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('truck_owner') // ✅ Subcollection inside user's document
          .doc("details") // ✅ Single "details" document inside subcollection
          .set(truckData, SetOptions(merge: true));

      print("✅ Truck Owner Data saved successfully.");
    } catch (e) {
      print("🔥 Error saving Truck Owner Data: $e");
      throw Exception("Failed to save truck owner data.");
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ Function to create Cargo Transporter Data
  Future<void> createCargoTransporterData(
      String userId, Map<String, dynamic> cargoData) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cargo_transporter') // ✅ Subcollection
          .doc("details") // ✅ Use "details" as document ID
          .set(cargoData, SetOptions(merge: true));

      print("✅ Cargo Transporter Data saved successfully.");
    } catch (e) {
      print("🔥 Error saving Cargo Transporter Data: $e");
      throw Exception("Failed to save cargo transporter data.");
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ Function to create Business Owner Data
  Future<void> createBusinessOwnerData(
      String userId, Map<String, dynamic> businessData) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('business_owner') // ✅ Subcollection
          .doc("details") // ✅ Use "details" as document ID
          .set(businessData, SetOptions(merge: true));

      print("✅ Business Owner Data saved successfully.");
    } catch (e) {
      print("🔥 Error saving Business Owner Data: $e");
      throw Exception("Failed to save business owner data.");
    }
  }
}
