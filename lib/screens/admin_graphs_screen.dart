import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AdminGraphsScreen extends StatefulWidget {
  @override
  _AdminGraphsScreenState createState() => _AdminGraphsScreenState();
}

class _AdminGraphsScreenState extends State<AdminGraphsScreen> {
  Map<String, int> bookingCounts = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final bookings =
        await FirebaseFirestore.instance.collection('bookings').get();

    Map<String, int> statusMap = {
      'Pending': 0,
      'Accepted': 0,
      'Rejected': 0,
      'Delivered': 0,
    };

    for (var doc in bookings.docs) {
      final status = doc['status'] ?? 'Unknown';
      if (statusMap.containsKey(status)) {
        statusMap[status] = statusMap[status]! + 1;
      }
    }

    setState(() {
      bookingCounts = statusMap;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Bookings Graphs",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 16),
            Text(
              "📦 Booking Distribution",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Container(
              height: 300,
              padding: EdgeInsets.all(20),
              child: PieChart(
                PieChartData(
                  sections: bookingCounts.entries.map((e) {
                    return PieChartSectionData(
                      title: "${e.value}",
                      value: e.value.toDouble(),
                      radius: 60,
                      titleStyle:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      color: _getStatusColor(e.key),
                    );
                  }).toList(),
                ),
              ),
            ),
            _buildLegend(),
            SizedBox(height: 16),
            Text(
              "📊 Booking Trend",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Container(
              height: 300,
              padding: EdgeInsets.all(20),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) => SizedBox(),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  barGroups: bookingCounts.entries.map((e) {
                    return BarChartGroupData(
                      x: _getStatusIndex(e.key),
                      barRods: [
                        BarChartRodData(
                          toY: e.value.toDouble(),
                          color: _getStatusColor(e.key),
                          width: 20,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            _buildLegend(),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // Get color for each booking status
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Delivered':
        return Colors.blue;
      case 'Pending':
      default:
        return Colors.orange;
    }
  }

  // Get X-axis index based on status
  int _getStatusIndex(String status) {
    switch (status) {
      case 'Pending':
        return 0;
      case 'Accepted':
        return 1;
      case 'Rejected':
        return 2;
      case 'Delivered':
        return 3;
      default:
        return 0;
    }
  }

  // Legend for chart colors
  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(Colors.orange, 'Pending'),
          SizedBox(width: 12),
          _legendItem(Colors.green, 'Accepted'),
          SizedBox(width: 12),
          _legendItem(Colors.red, 'Rejected'),
          SizedBox(width: 12),
          _legendItem(Colors.blue, 'Delivered'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          color: color,
        ),
        SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
