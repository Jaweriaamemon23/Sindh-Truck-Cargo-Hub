import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sindh_truck_cargo_hub/screens/available_user.dart';
import 'package:sindh_truck_cargo_hub/screens/feedback.dart';
import 'package:sindh_truck_cargo_hub/screens/filtered_bookings_screen.dart';
import 'package:sindh_truck_cargo_hub/screens/FilteredUsersScreen.dart';

class ReportsScreen extends StatelessWidget {
  Future<int> getTotalUsers() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();

    final filteredUsers = snapshot.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['userType'] == 'Admin') return false;
      if (data['email'] == 'sindhtruckcargohub@gmail.com') return false;
      return true;
    }).toList();

    return filteredUsers.length;
  }

  Future<int> getUserCountByType(String type) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('userType', isEqualTo: type)
        .get();
    return snapshot.size;
  }

  Future<int> getTotalBookings() async =>
      (await FirebaseFirestore.instance.collection('bookings').get()).size;

  Future<int> getBookingCountByStatus(String status) async {
    var snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('status', isEqualTo: status)
        .get();
    return snapshot.size;
  }

  Future<int> getTotalFeedback() async =>
      (await FirebaseFirestore.instance.collection('reviews').get()).size;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("System Reports", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade800,
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<int>>(
        future: Future.wait([
          getTotalUsers(),
          getUserCountByType('Truck Owner'),
          getUserCountByType('Cargo Transporter'),
          getUserCountByType('Business Owner'),
          getTotalBookings(),
          getBookingCountByStatus('Pending'),
          getBookingCountByStatus('Accepted'),
          getBookingCountByStatus('Rejected'),
          getBookingCountByStatus('Delivered'),
          getTotalFeedback(),
        ]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: [
                Text("📊 System Summary",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800)),
                SizedBox(height: 24),

                // User Stats
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AvailableUsersScreen()),
                    );
                  },
                  child: _buildReportTile("👥 Total Users", data[0]),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              FilteredUsersScreen(userType: 'Truck Owner')),
                    );
                  },
                  child: _buildReportTile("🚛 Truck Owners", data[1]),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => FilteredUsersScreen(
                              userType: 'Cargo Transporter')),
                    );
                  },
                  child: _buildReportTile("🧑‍🔧 Cargo Transporters", data[2]),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              FilteredUsersScreen(userType: 'Business Owner')),
                    );
                  },
                  child: _buildReportTile("🏢 Business Owners", data[3]),
                ),
                SizedBox(height: 16),

                // Booking Stats
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              FilteredBookingsScreen(status: "All")),
                    );
                  },
                  child: _buildReportTile("📦 Total Bookings", data[4]),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              FilteredBookingsScreen(status: "Pending")),
                    );
                  },
                  child: _buildReportTile("⏳ Pending Cargos", data[5]),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              FilteredBookingsScreen(status: "Accepted")),
                    );
                  },
                  child: _buildReportTile("✅ Accepted Cargos", data[6]),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              FilteredBookingsScreen(status: "Rejected")),
                    );
                  },
                  child: _buildReportTile("❌ Rejected Cargos", data[7]),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              FilteredBookingsScreen(status: "Delivered")),
                    );
                  },
                  child: _buildReportTile("📬 Delivered Cargos", data[8]),
                ),
                SizedBox(height: 16),

                // Feedback
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => FeedbackScreen()),
                    );
                  },
                  child: _buildReportTile("💬 Total Feedback", data[9]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportTile(String title, int value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(value.toString(),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900)),
        ],
      ),
    );
  }
}
