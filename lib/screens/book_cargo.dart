import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'cargo_tracking_screen.dart';
import 'cargo_actions.dart';
import '../providers/language_provider.dart';
import '../services/location_service.dart';
import 'dart:convert';

class BookCargoScreen extends StatefulWidget {
  @override
  _BookCargoScreenState createState() => _BookCargoScreenState();
}

class _BookCargoScreenState extends State<BookCargoScreen> {
  String selectedFilter = 'All';
  Set<String> awaitingConfirmation = {};
  Map<String, String> localBookingStatuses = {};
  Map<String, Timer> confirmationTimers = {};

  @override
  void initState() {
    super.initState();
    _loadLocalStatuses();
  }

  Future<void> _loadLocalStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final statusKey = 'booking_statuses_${user.uid}';
    final statusData = prefs.getString(statusKey);
    if (statusData != null) {
      setState(() {
        localBookingStatuses =
            Map<String, String>.from(Map<String, dynamic>.from(
                jsonDecode(statusData) as Map<String, dynamic>));
      });
    }
  }

  Future<void> _saveLocalStatus(String bookingId, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    localBookingStatuses[bookingId] = status;
    final statusKey = 'booking_statuses_${user.uid}';
    await prefs.setString(statusKey, jsonEncode(localBookingStatuses));

    if (status == 'LocallyAccepted') {
      setState(() {
        awaitingConfirmation.add(bookingId);
      });

      confirmationTimers[bookingId]?.cancel();
      confirmationTimers[bookingId] = Timer(Duration(seconds: 60), () {
        setState(() {
          awaitingConfirmation.remove(bookingId);
          localBookingStatuses.remove(bookingId);
          confirmationTimers.remove(bookingId);
        });
        _saveLocalStatus(bookingId, '');
      });
    } else {
      setState(() {
        awaitingConfirmation.remove(bookingId);
        confirmationTimers[bookingId]?.cancel();
        confirmationTimers.remove(bookingId);
      });
    }
  }

  @override
  void dispose() {
    confirmationTimers.values.forEach((timer) => timer.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSindhi = Provider.of<LanguageProvider>(context).isSindhi;
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSindhi ? "ڪارجو ڪتاب ڪريو" : "Book Cargo Requests",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  isSindhi ? "فلٽر:" : "Filter:",
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(width: 10),
                DropdownButton<String>(
                  value: selectedFilter,
                  items: ['All', 'Accepted', 'Pending'].map((filter) {
                    return DropdownMenuItem<String>(
                      value: filter,
                      child: Text(isSindhi
                          ? (filter == 'All'
                              ? 'سڀئي'
                              : filter == 'Accepted'
                                  ? 'قبول ٿيل'
                                  : 'زير التواءِ')
                          : filter),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedFilter = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('bookings').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(isSindhi
                        ? "❌ بوڪنگس لوڊ ڪرڻ ۾ غلطي!"
                        : "❌ Error loading bookings!"),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                var bookings = snapshot.data?.docs ?? [];

                bookings = bookings.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  List<dynamic> rejectedBy = data['rejectedBy'] ?? [];
                  List<dynamic> removedBy = data['removedBy'] ?? [];
                  bool notRejected = !(rejectedBy.contains(currentUser?.uid) ||
                      removedBy.contains(currentUser?.uid));

                  if (selectedFilter == 'All') return notRejected;
                  if (selectedFilter == 'Accepted') {
                    return notRejected &&
                        data['status'] == 'Accepted' &&
                        data['acceptedBy'] == currentUser?.email;
                  }
                  if (selectedFilter == 'Pending') {
                    return notRejected && data['status'] == 'Pending';
                  }
                  return false;
                }).toList();

                if (bookings.isEmpty) {
                  return Center(
                    child: Text(isSindhi
                        ? "ڪابه بوڪنگ دستياب ناهي."
                        : "No bookings available."),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    var bookingDoc = bookings[index];
                    var bookingData = bookingDoc.data() as Map<String, dynamic>;
                    String bookingId = bookingDoc.id;

                    String status = bookingData['status'] ?? 'Pending';
                    String acceptedBy = bookingData['acceptedBy'] ?? '';
                    String requestedByEmail = bookingData['email'] ?? '';

                    bool isAcceptedByAnother = status == "Accepted" &&
                        acceptedBy != currentUser?.email;
                    String displayStatus = isAcceptedByAnother
                        ? (isSindhi ? "دستياب ناهي" : "Not Available")
                        : localBookingStatuses[bookingId] == 'LocallyAccepted'
                            ? (isSindhi ? "قبول ڪيل (مقامي)" : "Accepted (Local)")
                            : status;

                    return FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .where('email', isEqualTo: requestedByEmail)
                          .limit(1)
                          .get(),
                      builder: (context, userSnapshot) {
                        String requestedByPhone =
                            isSindhi ? "لوڊ ٿي رهيو آهي..." : "Loading...";

                        if (userSnapshot.connectionState ==
                            ConnectionState.done) {
                          if (userSnapshot.hasData &&
                              userSnapshot.data!.docs.isNotEmpty) {
                            var userData = userSnapshot.data!.docs.first.data()
                                as Map<String, dynamic>;
                            requestedByPhone =
                                userData['phone'] ?? "Not Provided";
                          } else {
                            requestedByPhone =
                                isSindhi ? "يوزر نٿو ملي" : "User not found";
                          }
                        }

                        return Card(
                          elevation: 3,
                          margin: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.local_shipping,
                                        color: Colors.blue, size: 30),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "${isSindhi ? 'ڪارگو:' : 'Cargo:'} ${bookingData['cargoType'] ?? 'N/A'}",
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                    "${isSindhi ? 'کان:' : 'From:'} ${bookingData['startCity'] ?? 'Unknown'}"),
                                Text(
                                    "${isSindhi ? 'تائئن:' : 'To:'} ${bookingData['endCity'] ?? 'Unknown'}"),
                                Text(
                                    "${isSindhi ? 'وزن:' : 'Weight:'} ${bookingData['weight']} tons"),
                                Text(
                                    "${isSindhi ? 'فاصلو:' : 'Distance:'} ${bookingData['distance']} km"),
                                Text(
                                    "${isSindhi ? 'قيمت:' : 'Price:'} Rs. ${bookingData['price']}"),
                                Text(
                                    "${isSindhi ? 'فون:' : 'Phone:'} $requestedByPhone"),
                                Text(
                                  "${isSindhi ? 'حالت:' : 'Status:'} $displayStatus",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: getStatusColor(displayStatus),
                                  ),
                                ),
                                SizedBox(height: 10),
                                if (status == 'Pending' &&
                                    !awaitingConfirmation.contains(bookingId))
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: Text(isSindhi
                                                  ? 'پڪ ڪريو'
                                                  : 'Confirm'),
                                              content: Text(isSindhi
                                                  ? 'ڇا توهان واقعي هيءَ بوڪنگ قبول ڪرڻ چاهيو ٿا؟'
                                                  : 'Are you sure you want to accept this booking?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop(),
                                                  child: Text(
                                                      isSindhi ? 'نه' : 'No'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.of(ctx).pop();
                                                    _saveLocalStatus(bookingId,
                                                        'LocallyAccepted');
                                                  },
                                                  child: Text(
                                                      isSindhi ? 'ها' : 'Yes'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.check,
                                            color: Colors.white),
                                        label: Text(
                                          isSindhi ? "قبول ڪريو" : "Accept",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: Text(isSindhi
                                                  ? 'پڪ ڪريو'
                                                  : 'Confirm'),
                                              content: Text(isSindhi
                                                  ? 'ڇا توهان واقعي هيءَ بوڪنگ رد ڪرڻ چاهيو ٿا؟'
                                                  : 'Are you sure you want to reject this booking?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop(),
                                                  child: Text(
                                                      isSindhi ? 'نه' : 'No'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.of(ctx).pop();
                                                    rejectCargo(
                                                        bookingId, context);
                                                  },
                                                  child: Text(
                                                      isSindhi ? 'ها' : 'Yes'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.cancel,
                                            color: Colors.white),
                                        label: Text(
                                          isSindhi ? "رد ڪريو" : "Reject",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (awaitingConfirmation.contains(bookingId))
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: Text(isSindhi
                                                  ? 'پڪ ڪريو'
                                                  : 'Confirm'),
                                              content: Text(isSindhi
                                                  ? 'ڇا توهان واقعي هيءَ بوڪنگ جي تصديق ڪرڻ چاهيو ٿا؟'
                                                  : 'Are you sure you want to confirm this booking?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop(),
                                                  child: Text(
                                                      isSindhi ? 'نه' : 'No'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.of(ctx).pop();
                                                    acceptCargo(
                                                        bookingId, context);
                                                    _saveLocalStatus(
                                                        bookingId, 'Accepted');
                                                  },
                                                  child: Text(
                                                      isSindhi ? 'ها' : 'Yes'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.check_circle,
                                            color: Colors.white),
                                        label: Text(
                                          isSindhi ? "تصديق" : "Confirm",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: Text(isSindhi
                                                  ? 'پڪ ڪريو'
                                                  : 'Confirm'),
                                              content: Text(isSindhi
                                                  ? 'ڇا توهان واقعي هيءَ بوڪنگ منسوخ ڪرڻ چاهيو ٿا؟'
                                                  : 'Are you sure you want to cancel this booking?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop(),
                                                  child: Text(
                                                      isSindhi ? 'نه' : 'No'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.of(ctx).pop();
                                                    _saveLocalStatus(
                                                        bookingId, '');
                                                  },
                                                  child: Text(
                                                      isSindhi ? 'ها' : 'Yes'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.cancel,
                                            color: Colors.white),
                                        label: Text(
                                          isSindhi ? "منسوخ" : "Cancel",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (status == "Accepted" &&
                                    acceptedBy == currentUser?.email)
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (ctx) => AlertDialog(
                                              title: Text(isSindhi
                                                  ? 'پڪ ڪريو'
                                                  : 'Confirm'),
                                              content: Text(isSindhi
                                                  ? 'ڇا توهان واقعي هن بوڪنگ کي پورو طور تي نشان لڳائڻ چاهيو ٿا؟'
                                                  : 'Are you sure you want to mark this booking as delivered?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop(),
                                                  child: Text(
                                                      isSindhi ? 'نه' : 'No'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.of(ctx).pop();
                                                    markAsDelivered(
                                                        bookingId, context);
                                                  },
                                                  child: Text(
                                                      isSindhi ? 'ها' : 'Yes'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.check_circle,
                                            color: Colors.white),
                                        label: Text(
                                          isSindhi
                                              ? "پورو ٿي ويو"
                                              : "Mark as Delivered",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  CargoTrackingScreen(
                                                      bookingId: bookingId),
                                            ),
                                          );
                                        },
                                        icon: Icon(Icons.location_on,
                                            color: Colors.white),
                                        label: Text(
                                          isSindhi ? "ٽريڪ ڪريو" : "Track",
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.purple,
                                        ),
                                      ),
                                    ],
                                  ),
                                if (isAcceptedByAnother)
                                  Center(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: Text(isSindhi
                                                ? 'پڪ ڪريو'
                                                : 'Confirm'),
                                            content: Text(isSindhi
                                                ? 'ڇا توهان واقعي هيءَ بوڪنگ لسٽ مان هٽائڻ چاهيو ٿا؟'
                                                : 'Are you sure you want to remove this booking from the list?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(ctx).pop(),
                                                child: Text(
                                                    isSindhi ? 'نه' : 'No'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.of(ctx).pop();
                                                  removeBooking(
                                                      bookingId, context);
                                                },
                                                child: Text(
                                                    isSindhi ? 'ها' : 'Yes'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      icon: Icon(Icons.delete_forever,
                                          color: Colors.white),
                                      label: Text(
                                        isSindhi ? "هٽايو" : "Remove",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> markAsDelivered(String bookingId, BuildContext context) async {
    try {
      final position = await LocationService.getCurrentLocation();
      final city = await LocationService.getCityFromCoordinates(position);

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({'status': 'Delivered'});

      await FirebaseFirestore.instance
          .collection('cargo_tracking')
          .doc(bookingId)
          .collection('progress')
          .add({
        'booking_id': bookingId,
        'city': city.trim().toLowerCase(),
        'timestamp': DateTime.now().toString(),
        'delivered': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Marked as delivered and location updated."),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to mark as delivered: $e")),
      );
    }
  }

  Future<void> removeBooking(String bookingId, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'removedBy': FieldValue.arrayUnion([user.uid]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking removed successfully.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to remove booking: $e")),
      );
    }
  }

  Color getStatusColor(String status) {
    if (status.contains('Accepted (Local)')) return Colors.green.shade300;
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'delivered':
        return Colors.blue;
      case 'not available':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}