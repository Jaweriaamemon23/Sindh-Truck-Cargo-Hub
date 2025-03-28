import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> addCargo(String userId, Map<String, dynamic> cargoData) async {
    await _firestore.collection("users").doc(userId).collection("cargoRequests").add(cargoData);
  }
}
