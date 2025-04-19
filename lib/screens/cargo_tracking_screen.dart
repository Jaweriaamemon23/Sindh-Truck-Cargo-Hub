import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sindh_truck_cargo_hub/services/location_service.dart';
import 'package:sindh_truck_cargo_hub/providers/language_provider.dart';

class CargoTrackingScreen extends StatefulWidget {
  final String? bookingId;

  const CargoTrackingScreen({super.key, this.bookingId});

  @override
  State<CargoTrackingScreen> createState() => _CargoTrackingScreenState();
}

class _CargoTrackingScreenState extends State<CargoTrackingScreen> {
  List<Map<String, dynamic>> bookingDetails = [];
  String? selectedBookingId;
  String? currentCity;
  String bookingStatus = 'pending';
  String? truckOwnerEmail;
  bool isLoadingBookings = true;

  StreamSubscription<Position>? positionSubscription;

  @override
  void initState() {
    super.initState();
    fetchUserBookings();

    if (widget.bookingId != null) {
      selectedBookingId = widget.bookingId;
      startTracking(widget.bookingId!);
      fetchBookingStatus(widget.bookingId!);
    }
  }

  @override
  void dispose() {
    positionSubscription?.cancel();
    super.dispose();
  }

  Future<void> fetchUserBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    final userEmail = user?.email;

    if (userEmail == null) return;

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('email', isEqualTo: userEmail)
          .get();

      final bookings = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'startCity': data['startCity'] ?? 'Unknown',
          'endCity': data['endCity'] ?? 'Unknown',
          'status': data['status'] ?? 'Unknown',
          'acceptedBy': data['acceptedBy'] ?? 'Unknown',
          'cargoType': data['cargoType'] ?? 'Unknown',
          'weight': data['weight']?.toString() ?? '0',
        };
      }).toList();

      if (mounted) {
        setState(() {
          bookingDetails = bookings;
          isLoadingBookings = false;
        });
      }
    } catch (e) {
      _showSnackbar("Failed to fetch bookings: $e");
    }
  }

  Future<void> startTracking(String bookingId) async {
    positionSubscription?.cancel();

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        _showSnackbar("Location permission is required to track cargo.");
        return;
      }
    }

    try {
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();
      final acceptedBy = bookingDoc['acceptedBy'];
      final userEmail = FirebaseAuth.instance.currentUser?.email;

      if (acceptedBy != null &&
          acceptedBy != 'Unknown' &&
          acceptedBy == userEmail) {
        truckOwnerEmail = acceptedBy;

        positionSubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(distanceFilter: 500),
        ).listen((Position position) async {
          try {
            final newCity =
                (await LocationService.getCityFromCoordinates(position))
                    .trim()
                    .toLowerCase();

            if (newCity != currentCity) {
              currentCity = newCity;
              await logCityProgress(bookingId);
            }
          } catch (e) {
            _showSnackbar("Location error: $e");
          }
        });
      }
    } catch (e) {
      _showSnackbar("Booking not accepted yet!");
    }
  }

  Future<void> logCityProgress(String bookingId) async {
    try {
      final position = await LocationService.getCurrentLocation();
      final city = (await LocationService.getCityFromCoordinates(position))
          .trim()
          .toLowerCase();
      final timestamp = _formattedTimestamp();

      await FirebaseFirestore.instance
          .collection('cargo_tracking')
          .doc(bookingId)
          .collection('progress')
          .add({'city': city, 'timestamp': timestamp});
    } catch (e) {
      _showSnackbar("Failed to log city: $e");
    }
  }

  String _formattedTimestamp({DateTime? date}) {
    final now = date ?? DateTime.now();
    return DateFormat('dd MMM yyyy – hh:mm a').format(now);
  }

  void fetchBookingStatus(String bookingId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();
      final data = doc.data();

      if (data != null && mounted) {
        setState(() {
          bookingStatus = data['status'] ?? 'pending';
        });
      }
    } catch (e) {
      _showSnackbar("Error fetching status: $e");
    }
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSindhi = context.watch<LanguageProvider>().isSindhi;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                isSindhi ? "ڪارگو ٽريڪنگ" : "Cargo Tracking",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 13, 71, 161),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.bookingId == null) ...[
                if (isLoadingBookings)
                  const CircularProgressIndicator()
                else if (bookingDetails.isNotEmpty)
                  _buildBookingDropdown(isSindhi)
                else
                  Text(
                    isSindhi
                        ? "ٽريڪ ڪرڻ لاءِ ڪا به بوڪنگ ناهي"
                        : "No bookings available for tracking",
                  ),
                const SizedBox(height: 20),
              ],
              Expanded(child: _buildTrackingProgress(isSindhi)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackingProgress(bool isSindhi) {
    if (selectedBookingId == null) {
      return Center(
        child: Text(
          isSindhi
              ? "ٽريڪ ڪرڻ لاءِ ڪا بوڪنگ منتخب ناهي ڪئي وئي."
              : "No booking selected for tracking.",
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cargo_tracking')
          .doc(selectedBookingId)
          .collection('progress')
          .orderBy('timestamp')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(isSindhi
                ? "ٽريڪنگ ڊيٽا لوڊ ڪرڻ ۾ نقص."
                : "Error loading tracking data."),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final progressDocs = snapshot.data?.docs ?? [];

        if (progressDocs.isEmpty && bookingStatus == 'accepted') {
          return Center(
            child: Text(isSindhi
                ? "ٽرڪ مالڪ کي لاگ ان ٿيڻ جي ضرورت آهي."
                : "Truck owner needs to login to update location."),
          );
        } else if (progressDocs.isEmpty) {
          return Center(
            child: Text(isSindhi
                ? "ٽريڪنگ ڊيٽا اڃا تائين موجود ناهي."
                : "No tracking data available yet."),
          );
        }

        return ListView.separated(
          itemCount: progressDocs.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final data = progressDocs[index].data() as Map<String, dynamic>;
            final city = data['city'] ?? 'Unknown';
            final timestamp = data['timestamp'] ?? 'Unknown';

            return ListTile(
              leading: const Icon(Icons.location_on, color: Colors.blue),
              title: Text(city.toUpperCase()),
              subtitle: Text(timestamp),
            );
          },
        );
      },
    );
  }

  Widget _buildBookingDropdown(bool isSindhi) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: DropdownButtonFormField<String>(
        value: selectedBookingId,
        decoration: InputDecoration(
          labelText: isSindhi
              ? "بوڪنگ چونڊيو"
              : "Select Booking to Track",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        isExpanded: true,
        onChanged: (String? value) {
          if (value != null && value.isNotEmpty) {
            setState(() {
              selectedBookingId = value;
              bookingStatus = 'pending';
            });
            startTracking(value);
            fetchBookingStatus(value);
          }
        },
        selectedItemBuilder: (BuildContext context) {
          return bookingDetails.map<Widget>((booking) {
            return Text(
              '${booking['startCity']} → ${booking['endCity']} (${booking['status']})',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16),
            );
          }).toList();
        },
        items: bookingDetails.map((booking) {
          return DropdownMenuItem<String>(
            value: booking['id'],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${booking['cargoType']} (${booking['weight']} tons)',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text('${booking['startCity']} → ${booking['endCity']}'),
                Text('Accepted By: ${booking['acceptedBy']}'),
                Text(
                  'Status: ${booking['status']}',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                const Divider(thickness: 2),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
