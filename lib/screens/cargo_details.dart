import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './fcm_notification_handler.dart';
import './firebase_notification_service.dart';

class CargoDetailsScreen extends StatefulWidget {
  @override
  _CargoDetailsScreenState createState() => _CargoDetailsScreenState();
}

class _CargoDetailsScreenState extends State<CargoDetailsScreen> {
  final TextEditingController _weightController =
      TextEditingController(text: "0");
  final TextEditingController _distanceController =
      TextEditingController(text: "0");
  final TextEditingController _businessOwnerIdController =
      TextEditingController(); // ✅ For business owner ID

  String? selectedCargoType;
  String? selectedStartCity;
  String? selectedEndCity;

  final List<String> cargoTypes = [
    'General Goods',
    'Fragile Items',
    'Perishable Goods'
  ];
  final List<String> cities = ['Karachi', 'Hyderabad', 'Sukkur', 'Larkana'];

  double? estimatedPrice;

  // Predefined list of distances with city-to-city info
  final List<Map<String, dynamic>> predefinedDistances = [
    {"route": "Karachi → Hyderabad", "distance": 167},
    {"route": "Karachi → Larkana", "distance": 380},
    {"route": "Karachi → Sukkur", "distance": 450},
    {"route": "Hyderabad → Larkana", "distance": 210},
    {"route": "Hyderabad → Sukkur", "distance": 280},
    {"route": "Larkana → Sukkur", "distance": 125},
  ];

  void _calculatePrice() {
    int weight = int.tryParse(_weightController.text) ?? 0;
    int distance = int.tryParse(_distanceController.text) ?? 0;

    if (weight > 0 && distance > 0) {
      setState(() {
        estimatedPrice = (weight * 2.5) + (distance * 1.5);
      });
    } else {
      setState(() {
        estimatedPrice = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Please enter valid weight and distance'),
            backgroundColor: Colors.red),
      );
    }
  }

// Store Notification in Firestore for future tracking
  Future<void> storeNotificationInFirestore({
    required String cargoDetails,
    required String weight,
    required String fromLocation,
    required String toLocation,
    required String distance,
    required String vehicleType,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'cargoDetails': cargoDetails,
        'weight': weight,
        'fromLocation': fromLocation,
        'toLocation': toLocation,
        'distance': distance,
        'vehicleType': vehicleType,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error storing notification in Firestore: $e");
    }
  }

  Future<void> _requestBooking() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must be logged in to request a booking'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedCargoType == null ||
        selectedStartCity == null ||
        selectedEndCity == null ||
        estimatedPrice == null ||
        _businessOwnerIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete all details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    String businessOwnerId = _businessOwnerIdController.text.trim();

    // ✅ Validate Business Owner UID & Role
    DocumentSnapshot ownerSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(businessOwnerId)
        .get();

    if (!ownerSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ No user found with this ID.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    var ownerData = ownerSnapshot.data() as Map<String, dynamic>?;

    if (ownerData == null || ownerData['userType'] != 'Business Owner') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ This UID does not belong to a Business Owner.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ Store booking
    await FirebaseFirestore.instance.collection('bookings').add({
      'cargoType': selectedCargoType,
      'startCity': selectedStartCity,
      'endCity': selectedEndCity,
      'weight': _weightController.text,
      'distance': _distanceController.text,
      'price': estimatedPrice,
      'email': user.email,
      'timestamp': FieldValue.serverTimestamp(),
      'transporterId': user.uid,
      'businessOwnerId': businessOwnerId, // ✅ Store for tracking
      'status': 'Pending',
    });

    // ✅ Debugging Statements for Notification Trigger
    print("🚀 Triggering push notification to truck owners...");
// ✅ Send FCM Notification to Truck Owners
    await sendFCMNotificationToTruckOwners(
      cargoDetails: selectedCargoType ?? "Unknown Cargo",
      weight: _weightController.text,
      fromLocation: selectedStartCity ?? "Unknown",
      toLocation: selectedEndCity ?? "Unknown",
      distance: _distanceController.text,
      vehicleType: 'Truck', // You can replace with dynamic if needed
    );
    print("✅ Notification sent to truck owners!");

// ✅ Store Notification in Firestore for future tracking
    await storeNotificationInFirestore(
      cargoDetails: selectedCargoType ?? "Unknown Cargo",
      weight: _weightController.text,
      fromLocation: selectedStartCity ?? "Unknown",
      toLocation: selectedEndCity ?? "Unknown",
      distance: _distanceController.text,
      vehicleType: 'Truck', // Replace with dynamic if needed
    );
    // ✅ Show confirmation message to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking Requested Successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    // ✅ Reset the form after successful booking request
    setState(() {
      selectedCargoType = null;
      selectedStartCity = null;
      selectedEndCity = null;
      _weightController.text = "0";
      _distanceController.text = "0";
      _businessOwnerIdController.clear();
      estimatedPrice = null;
    });

    // ✅ Close the current screen after booking request
    Navigator.pop(context);
  }

  Widget _buildDropdown(String label, String? selectedValue,
      List<String> options, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
        SizedBox(height: 5),
        DropdownButtonFormField<String>(
          value: selectedValue,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: options.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  // Function to show distance chart dialog with updated list
  void _showDistanceChart() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Distance'),
          content: SingleChildScrollView(
            child: Column(
              children: predefinedDistances.map((distanceData) {
                return ListTile(
                  title: Text(
                      '${distanceData["route"]} : ${distanceData["distance"]} km'),
                  onTap: () {
                    setState(() {
                      _distanceController.text =
                          distanceData["distance"].toString();
                    });
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Add Cargo Details', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWeightInput(),
              SizedBox(height: 10),
              _buildDropdown('Cargo Type', selectedCargoType, cargoTypes,
                  (newValue) {
                setState(() {
                  selectedCargoType = newValue;
                });
              }),
              SizedBox(height: 10),
              _buildDropdown('Start City', selectedStartCity, cities,
                  (newValue) {
                setState(() {
                  selectedStartCity = newValue;
                });
              }),
              SizedBox(height: 10),
              _buildDropdown('End City', selectedEndCity, cities, (newValue) {
                setState(() {
                  selectedEndCity = newValue;
                });
              }),
              SizedBox(height: 10),
              _buildDistanceInput(),
              SizedBox(height: 10),
              _buildBusinessOwnerIdField(),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _calculatePrice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      Text('Calculate Price', style: TextStyle(fontSize: 16)),
                ),
              ),
              SizedBox(height: 20),
              if (estimatedPrice != null)
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Estimated Price: Rs. ${estimatedPrice!.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _requestBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text('Request Booking',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeightInput() {
    return _buildInputWithButtons('Cargo Weight (kg)', _weightController);
  }

  Widget _buildDistanceInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Distance (km)',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
        SizedBox(height: 5),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.list, color: Colors.blue),
              onPressed: _showDistanceChart, // Show distance chart when clicked
            ),
            SizedBox(
              width: 60,
              child: TextField(
                controller: _distanceController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(border: OutlineInputBorder()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputWithButtons(
      String label, TextEditingController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () {
                int value = int.tryParse(controller.text) ?? 1;
                if (value > 1) {
                  setState(() {
                    controller.text = (value - 1).toString();
                  });
                }
              },
            ),
            SizedBox(
              width: 60,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(border: OutlineInputBorder()),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add_circle, color: Colors.green),
              onPressed: () {
                int value = int.tryParse(controller.text) ?? 0;
                setState(() {
                  controller.text = (value + 1).toString();
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBusinessOwnerIdField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Enter Business Owner ID (UID provided by owner)",
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
        SizedBox(height: 5),
        TextField(
          controller: _businessOwnerIdController,
          decoration: InputDecoration(
            hintText: 'Business Owner UID',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      ],
    );
  }
}
