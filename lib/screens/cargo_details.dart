import 'package:flutter/material.dart';

class CargoDetailsScreen extends StatefulWidget {
  @override
  _CargoDetailsScreenState createState() => _CargoDetailsScreenState();
}

class _CargoDetailsScreenState extends State<CargoDetailsScreen> {
  // Controllers for input fields
  final TextEditingController _weightController = TextEditingController(text: "0");
  final TextEditingController _distanceController = TextEditingController(text: "0");

  // Dropdown selections
  String? selectedCargoType;
  String? selectedStartCity;
  String? selectedEndCity;

  final List<String> cargoTypes = ['General Goods', 'Fragile Items', 'Perishable Goods'];
  final List<String> cities = ['Karachi', 'Hyderabad', 'Sukkur', 'Larkana'];

  double? estimatedPrice; // Variable to store the estimated price

  // Function to calculate estimated price
  void _calculatePrice() {
    int weight = int.tryParse(_weightController.text) ?? 0;
    int distance = int.tryParse(_distanceController.text) ?? 0;

    if (weight > 0 && distance > 0) {
      setState(() {
        estimatedPrice = (weight * 2.5) + (distance * 1.5); // Sample formula
      });
    } else {
      setState(() {
        estimatedPrice = null; // Reset price if input is invalid
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter valid weight and distance')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Cargo Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cargo Weight Input with Increment/Decrement Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cargo Weight (kg)', style: TextStyle(fontSize: 16)),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        int weight = int.tryParse(_weightController.text) ?? 1;
                        if (weight > 1) {
                          setState(() {
                            _weightController.text = (weight - 1).toString();
                          });
                        }
                      },
                    ),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(border: OutlineInputBorder()),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle, color: Colors.green),
                      onPressed: () {
                        int weight = int.tryParse(_weightController.text) ?? 0;
                        setState(() {
                          _weightController.text = (weight + 1).toString();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 10),

            // Cargo Type Dropdown
            DropdownButtonFormField<String>(
              value: selectedCargoType,
              decoration: InputDecoration(
                labelText: 'Cargo Type',
                border: OutlineInputBorder(),
              ),
              items: cargoTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedCargoType = newValue;
                });
              },
            ),
            SizedBox(height: 10),

            // Start City Dropdown
            DropdownButtonFormField<String>(
              value: selectedStartCity,
              decoration: InputDecoration(
                labelText: 'Start City',
                border: OutlineInputBorder(),
              ),
              items: cities.map((city) {
                return DropdownMenuItem<String>(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedStartCity = newValue;
                });
              },
            ),
            SizedBox(height: 10),

            // End City Dropdown
            DropdownButtonFormField<String>(
              value: selectedEndCity,
              decoration: InputDecoration(
                labelText: 'End City',
                border: OutlineInputBorder(),
              ),
              items: cities.map((city) {
                return DropdownMenuItem<String>(
                  value: city,
                  child: Text(city),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  selectedEndCity = newValue;
                });
              },
            ),
            SizedBox(height: 10),

            // Distance Input with Increment/Decrement Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Distance (km)', style: TextStyle(fontSize: 16)),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: () {
                        int distance = int.tryParse(_distanceController.text) ?? 1;
                        if (distance > 1) {
                          setState(() {
                            _distanceController.text = (distance - 1).toString();
                          });
                        }
                      },
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
                    IconButton(
                      icon: Icon(Icons.add_circle, color: Colors.green),
                      onPressed: () {
                        int distance = int.tryParse(_distanceController.text) ?? 0;
                        setState(() {
                          _distanceController.text = (distance + 1).toString();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),

            // Calculate Price Button
            Center(
              child: ElevatedButton(
                onPressed: _calculatePrice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Blue button color
                  foregroundColor: Colors.white, // Text color
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('Calculate Price', style: TextStyle(fontSize: 16)),
              ),
            ),
            SizedBox(height: 20),

            // Display Estimated Price
            if (estimatedPrice != null)
              Center(
                child: Text(
                  'Estimated Price: Rs. ${estimatedPrice!.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
