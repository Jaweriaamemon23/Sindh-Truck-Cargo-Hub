import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CargoDetailsScreen extends StatefulWidget {
  @override
  _CargoDetailsScreenState createState() => _CargoDetailsScreenState();
}

class _CargoDetailsScreenState extends State<CargoDetailsScreen> {
  final TextEditingController _weightController =
      TextEditingController(text: "0");
  final TextEditingController _distanceController =
      TextEditingController(text: "0");

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

  Future<void> _requestBooking() async {
    User? user = FirebaseAuth.instance.currentUser; // Get logged-in user

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
        estimatedPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete all details'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('bookings').add({
      'cargoType': selectedCargoType,
      'startCity': selectedStartCity,
      'endCity': selectedEndCity,
      'weight': _weightController.text,
      'distance': _distanceController.text,
      'price': estimatedPrice,
      'email': user.email, // Store user email in Firestore
      'timestamp': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Booking Requested Successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {
      selectedCargoType = null;
      selectedStartCity = null;
      selectedEndCity = null;
      _weightController.text = "0";
      _distanceController.text = "0";
      estimatedPrice = null;
    });
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
    return _buildInputWithButtons('Distance (km)', _distanceController);
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
}