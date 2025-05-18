import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'business_owner_functions.dart';
import '../providers/language_provider.dart';
import 'TrackingDetailsPage.dart';
import 'package:intl/intl.dart';

class BusinessOwnerDashboard extends StatefulWidget {
  @override
  _BusinessOwnerDashboardState createState() => _BusinessOwnerDashboardState();
}

class _BusinessOwnerDashboardState extends State<BusinessOwnerDashboard> {
  int _selectedIndex = 0;
  bool isLoading = true;
  List<Map<String, dynamic>> trackingList = [];
  String _statusFilter = 'All';
  TextEditingController _bookingIdController = TextEditingController();
  Map<String, dynamic>? trackedBooking;
  String? _selectedTrackingBookingId; // Track the selected booking ID

  @override
  void initState() {
    super.initState();
    BusinessOwnerFunctions.fetchBookingsForBusinessOwner(context, (bookings) {
      setState(() {
        isLoading = false;
        trackingList = bookings;
      });
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (_selectedIndex == 0) {
        // Fetch data again when "My Shipments" tab is selected
        isLoading = true;
        BusinessOwnerFunctions.fetchBookingsForBusinessOwner(context,
            (bookings) {
          setState(() {
            isLoading = false;
            trackingList = bookings;
          });
        });
      } else {
        // Clear tracking data when switching to "Track by ID"
        trackingList = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSindhi = Provider.of<LanguageProvider>(context).isSindhi;

    List<Widget> screens = [
      isLoading
          ? Center(child: CircularProgressIndicator())
          : _buildShipmentsTab(isSindhi),
      _buildTrackByIdScreen(context, isSindhi),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: Text(
          isSindhi ? "ڪاروباري مالڪ ڊيش بورڊ" : "Business Owner Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () => BusinessOwnerFunctions.logout(context),
            tooltip: isSindhi ? 'لاگ آئوٽ' : 'Logout',
          ),
          IconButton(
            icon: Icon(Icons.language, color: Colors.white),
            tooltip: isSindhi ? 'ٻولي مٽايو' : 'Change Language',
            onPressed: () {
              Provider.of<LanguageProvider>(context, listen: false)
                  .toggleLanguage();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.blue.shade800,
            child: Text(
              _selectedIndex == 0
                  ? (isSindhi ? 'منهنجون روانگيون' : 'My Shipments')
                  : (isSindhi ? 'ID سان روانگي ڳوليو' : 'Track Shipment by ID'),
              style: TextStyle(fontSize: 20, color: Colors.white),
            ),
          ),
          Expanded(child: screens[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue.shade800,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: isSindhi ? 'منهنجي روانگيون' : 'My Shipments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: isSindhi ? 'ID سان ڳوليو' : 'Track by ID',
          ),
        ],
      ),
    );
  }

  Widget _buildShipmentsTab(bool isSindhi) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusFilter(isSindhi),
          SizedBox(height: 20),
          Text(
            isSindhi ? "تمام روانگيون" : "All Shipments",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _getFilteredTrackingList().length,
            itemBuilder: (context, index) {
              final item = _getFilteredTrackingList()[index];
              String startCity = item['startCity'] ?? 'Unknown';
              String endCity = item['endCity'] ?? 'Unknown';
              String acceptedBy = item['acceptedBy'] ?? 'Not Accepted';
              String bookingId = item['bookingId'] ?? ''; // Document ID
              String cargoType =
                  item['cargoType'] ?? 'Unknown'; // Fetch cargoType

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: ListTile(
                      title: Text(
                        "$startCity → $endCity",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${isSindhi ? "قسم ڪارگو" : "Cargo Type"}: $cargoType",
                          ),
                          Text(
                            "${isSindhi ? "قبول ڪندڙ" : "Accepted By"}: $acceptedBy",
                          ),
                          if (acceptedBy != 'Not Accepted' &&
                              bookingId.isNotEmpty)
                            Text(
                              "${isSindhi ? "ٽريڪنگ ID" : "Tracking ID"}: $bookingId",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TrackingDetailsPage(
                              bookingId: bookingId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredTrackingList() {
    if (_statusFilter == 'Accepted') {
      return trackingList.where((item) => item['acceptedBy'] != null).toList();
    } else if (_statusFilter == 'Non-Accepted') {
      return trackingList.where((item) => item['acceptedBy'] == null).toList();
    } else {
      return trackingList;
    }
  }

  Widget _buildStatusFilter(bool isSindhi) {
    return Row(
      children: [
        Text(
          isSindhi ? "اسٽيٽس چونڊيو" : "Select Status",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        SizedBox(width: 10),
        DropdownButton<String>(
          value: _statusFilter,
          onChanged: (String? newValue) {
            setState(() {
              _statusFilter = newValue!;
            });
          },
          items: <String>['All', 'Accepted', 'Non-Accepted']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTrackByIdScreen(BuildContext context, bool isSindhi) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSindhi ? "بڪنگ ID داخل ڪريو" : "Enter Tracking ID",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _bookingIdController,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: isSindhi ? 'ID داخل ڪريو' : 'Enter Tracking ID here',
            ),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () async {
              String bookingId = _bookingIdController.text.trim();
              if (bookingId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isSindhi ? "ID ضروري آهي" : "ID is required"),
                ));
                return;
              }

              try {
                final doc = await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(bookingId)
                    .get();

                if (!doc.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content:
                        Text(isSindhi ? "بڪنگ نه ملي" : "Booking not found"),
                  ));
                  setState(() {
                    trackedBooking = null;
                    trackingList = [];
                  });
                } else {
                  final trackingSnapshot = await FirebaseFirestore.instance
                      .collection('cargo_tracking')
                      .doc(bookingId)
                      .collection('progress')
                      .orderBy('timestamp', descending: true)
                      .get();

                  setState(() {
                    trackedBooking = doc.data(); // Set the booking details
                    trackingList = trackingSnapshot.docs
                        .map((e) => Map<String, dynamic>.from(e.data()))
                        .toList(); // Set the tracking history
                  });
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isSindhi ? "غلطي ٿي" : "An error occurred"),
                ));
              }
            },
            child: Text(isSindhi ? "ڳوليو" : "Track"),
          ),
          SizedBox(height: 20),
          if (trackedBooking != null) ...[
            _buildTrackingDetails(
                trackedBooking!, isSindhi), // Display booking details
          ],
          if (trackingList.isNotEmpty) ...[
            SizedBox(height: 20),
            Text(
              isSindhi ? "ٽريڪنگ جي تاريخ" : "Tracking History",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: trackingList.length,
              itemBuilder: (context, index) {
                final item = trackingList[index];
                String formattedDate = item['timestamp'] ?? 'N/A';
                String city = item['city'] ?? 'Unknown';

                return Card(
                  child: ListTile(
                    title: Text("${isSindhi ? "شهر" : "Location"}: $city"),
                    subtitle:
                        Text("${isSindhi ? "وقت" : "Time"}: $formattedDate"),
                  ),
                );
              },
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildTrackingDetails(Map<String, dynamic> data, bool isSindhi) {
    final timestamp = data['timestamp'];
    String formattedDate = "N/A";

    if (timestamp != null && timestamp is Timestamp) {
      formattedDate =
          DateFormat('yyyy-MM-dd – kk:mm').format(timestamp.toDate());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoTile(isSindhi ? "شروعاتي شهر" : "Start City", data['startCity']),
        _infoTile(isSindhi ? "آخري شهر" : "End City", data['endCity']),
        _infoTile(isSindhi ? "اسٽيٽس" : "Status", data['status']),
        _infoTile(isSindhi ? "ماپ" : "Weight", data['weight']?.toString()),
        _infoTile(isSindhi ? "قيمت" : "Price", data['price']?.toString()),
        _infoTile(isSindhi ? "قبول ڪندڙ" : "Accepted By", data['acceptedBy']),
        _infoTile(isSindhi ? "وقت" : "Timestamp", formattedDate),
      ],
    );
  }

  Widget _infoTile(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$title: ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? "N/A")),
        ],
      ),
    );
  }
}

// 🔽 Inline tracking widget
class TrackingListWidget extends StatelessWidget {
  final String bookingId;

  const TrackingListWidget({required this.bookingId});

  @override
  Widget build(BuildContext context) {
    final isSindhi = Provider.of<LanguageProvider>(context).isSindhi;

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('cargo_tracking')
          .doc(bookingId)
          .collection('progress')
          .orderBy('timestamp', descending: true)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final trackingData = snapshot.data!.docs;

        if (trackingData.isEmpty) {
          return Text(
              isSindhi ? "ڪو ٽريڪنگ ڊيٽا ناهي" : "No tracking data found");
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: trackingData.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final city = data['city'] ?? 'Unknown';
            final time = data['timestamp'] ?? 'N/A';

            return Card(
              child: ListTile(
                title: Text("${isSindhi ? "شهر" : "City"}: $city"),
                subtitle: Text("${isSindhi ? "وقت" : "Time"}: $time"),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
