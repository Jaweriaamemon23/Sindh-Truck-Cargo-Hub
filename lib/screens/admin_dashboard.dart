import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:sindh_truck_cargo_hub/screens/admin_graphs_screen.dart';
import 'package:sindh_truck_cargo_hub/screens/reports_screen.dart';
import '../providers/language_provider.dart';
import 'login_screen.dart';
import 'available_user.dart';
import 'feedback.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  bool _isLoading = false;

  String _selectedYear = '2025';
  String _selectedCity = 'All';
  String _selectedStatus = 'All';
  String? _selectedMetric;

  List<String> years = ['2023', '2024', '2025'];
  List<String> cities = ['All', 'Karachi', 'Hyderabad', 'Sukkur'];
  List<String> statuses = [
    'All',
    'Delivered',
    'Accepted',
    "Unconfirmed",
    "Rejected"
  ];

  List<FlSpot> _monthlyBookings = [];
  List<FlSpot> _dailyBookings = [];

  int totalUsers = 0;
  int totalTrucks = 0;
  int totalBookings = 0;
  int completedBookings = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    await _fetchBookingData();
    await _fetchDayWiseBookingData();
  }

  Future<void> _fetchBookingData() async {
    setState(() => _isLoading = true);

    try {
      Query query = FirebaseFirestore.instance.collection('bookings');

      if (_selectedYear != 'All') {
        final int year = int.parse(_selectedYear);
        final start = DateTime(year, 1, 1);
        final end = DateTime(year, 12, 31, 23, 59, 59);
        query = query
            .where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end));
      }

      if (_selectedStatus != 'All') {
        query = query.where('status', isEqualTo: _selectedStatus);
      }

      final snapshot = await query.get();

      List<int> monthlyCounts = List.filled(12, 0);
      totalTrucks = 0;
      totalBookings = snapshot.docs.length;
      completedBookings = 0;

      for (var doc in snapshot.docs) {
        final timestamp = doc['timestamp'] as Timestamp;
        final date = timestamp.toDate();
        monthlyCounts[date.month - 1]++;

        final status = doc['status'] ?? '';

        if (status == 'Accepted') totalTrucks++;
        if (status == 'Delivered') completedBookings++;
      }

      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      totalUsers = usersSnapshot.docs.length;

      setState(() {
        _monthlyBookings = List.generate(
          12,
          (index) => FlSpot(index.toDouble(), monthlyCounts[index].toDouble()),
        );
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching booking data: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDayWiseBookingData() async {
    setState(() => _isLoading = true);

    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: 9));
      List<int> dailyCounts = List.filled(10, 0);

      for (int i = 0; i < 10; i++) {
        final dayStart =
            DateTime(startDate.year, startDate.month, startDate.day + i);
        final dayEnd = dayStart.add(Duration(days: 1));

        Query query = FirebaseFirestore.instance
            .collection('bookings')
            .where('timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
            .where('timestamp', isLessThan: Timestamp.fromDate(dayEnd));

        if (_selectedStatus != 'All') {
          query = query.where('status', isEqualTo: _selectedStatus);
        }

        final snapshot = await query.get();
        dailyCounts[i] = snapshot.size;
      }

      setState(() {
        _dailyBookings = List.generate(
          10,
          (index) => FlSpot(index.toDouble(), dailyCounts[index].toDouble()),
        );
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching day-wise data: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSindhi = Provider.of<LanguageProvider>(context).isSindhi;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade800,
        title: Text(
          isSindhi ? 'ايڊمن ڊيش بورڊ' : 'Admin Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(icon: Icon(Icons.logout, color: Colors.white), onPressed: _logout),
          IconButton(
              icon: Icon(Icons.language, color: Colors.white),
              onPressed: () {
                Provider.of<LanguageProvider>(context, listen: false)
                    .toggleLanguage();
              }),
        ],
      ),
      drawer: _buildDrawer(isSindhi),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildDashboardCard(Icons.person, 'Total Users',
                    totalUsers.toString(), Colors.teal),
                _buildDashboardCard(Icons.local_shipping, 'Accepted Booking',
                    totalTrucks.toString(), Colors.deepOrange),
                _buildDashboardCard(Icons.book_online, 'Total Bookings',
                    totalBookings.toString(), Colors.indigo),
                _buildDashboardCard(Icons.check, 'Delivered',
                    completedBookings.toString(), Colors.green),
              ],
            ),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown('Year', years, _selectedYear, (val) {
                    setState(() => _selectedYear = val);
                    _fetchAllData();
                  }),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _buildDropdown('Status', statuses, _selectedStatus,
                      (val) {
                    setState(() => _selectedStatus = val);
                    _fetchAllData();
                  }),
                ),
              ],
            ),
            SizedBox(height: 20),
            _selectedMetric == null
                ? Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        tabs: [
                          Tab(text: 'Monthly Report'),
                          Tab(text: 'Day-wise Report'),
                        ],
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 400,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _isLoading
                                ? Center(child: CircularProgressIndicator())
                                : _buildLineChart(_monthlyBookings),
                            _isLoading
                                ? Center(child: CircularProgressIndicator())
                                : _buildLineChart(_dailyBookings),
                          ],
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Showing report for: $_selectedMetric',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Container(
                          height: 400,
                          child: _isLoading
                              ? Center(child: CircularProgressIndicator())
                              : _buildLineChart(_monthlyBookings)),
                      TextButton.icon(
                        onPressed: () => setState(() => _selectedMetric = null),
                        icon: Icon(Icons.arrow_back),
                        label: Text("Back to Full Report"),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<FlSpot> spots) {
    Color color = _getLineColor();
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 2, // ✅ Adjust based on your data
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString());
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (spots == _monthlyBookings) {
                  const months = [
                    'Jan',
                    'Feb',
                    'Mar',
                    'Apr',
                    'May',
                    'Jun',
                    'Jul',
                    'Aug',
                    'Sep',
                    'Oct',
                    'Nov',
                    'Dec'
                  ];
                  return Text(months[value.toInt() % 12]);
                } else {
                  final now = DateTime.now();
                  final day =
                      (now.subtract(Duration(days: 9 - value.toInt()))).day;
                  return Text(day.toString());
                }
              },
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // 👈 HIDE TOP AXIS
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false), // 👈 HIDE RIGHT AXIS
          ),
        ),
        minX: 0,
        maxX: spots.length.toDouble() - 1,
        minY: 0,
        maxY: spots.isEmpty
            ? 10
            : spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 5,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            belowBarData: BarAreaData(show: false),
          )
        ],
      ),
    );
  }

  Color _getLineColor() {
    switch (_selectedStatus) {
      case 'Completed':
        return Colors.green;
      case 'Unconfirmed':
        return Colors.red;
      case 'Confirmed':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Widget _buildDashboardCard(
      IconData icon, String title, String value, Color baseColor) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMetric = title;
        });
      },
      child: Container(
        width: (MediaQuery.of(context).size.width / 2) - 24,
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: baseColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
          border: _selectedMetric == title
              ? Border.all(color: baseColor, width: 2)
              : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: baseColor.withOpacity(0.85), size: 30),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: baseColor.withOpacity(0.85)),
            ),
            Text(
              value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: baseColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value,
      Function(String) onChanged) {
    return DropdownButton<String>(
      value: value,
      isExpanded: true,
      onChanged: (val) => onChanged(val!),
      items: items.map((e) {
        return DropdownMenuItem<String>(
          value: e,
          child: Text(e),
        );
      }).toList(),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  Widget _buildDrawer(bool isSindhi) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue.shade900, // Darker shade of blue
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.admin_panel_settings, size: 40, color: Colors.white),
                SizedBox(height: 10),
                Text(
                  'Admin',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
                Text(
                  'sindhtruckcargohub@gmail.com', // ✅ Updated email
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          ListTile(
            title: Text(isSindhi ? 'استعمال ڪندڙ' : 'Users'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AvailableUsersScreen()),
            ),
          ),
          ListTile(
            title: Text(isSindhi ? 'جائزن' : 'Complain'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FeedbackScreen()),
            ),
          ),
          ListTile(
            title: Text(isSindhi ? 'گراف ۽ رپورٽ' : 'Report'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReportsScreen()),
            ), // Already on dashboard
          ),
          ListTile(
            title: Text(isSindhi ? 'گراف ۽ رپورٽ' : 'Graph'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdminGraphsScreen()),
            ), // Already on dashboard
          ),
        ],
      ),
    );
  }
}