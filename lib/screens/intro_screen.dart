import 'package:flutter/material.dart';
import 'login_screen.dart'; // Import LoginScreen

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  _IntroScreenState createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  int currentPage = 0; // Track the current page
  final PageController _pageController =
      PageController(); // Controller for page navigation

  final List<Widget> pages = [
    IntroPage(
      title: "Vehicle Type",
      description: "Select your vehicle according to your requirement",
    ),
    IntroPage(
      title: "Track Your Vehicle",
      description: "Track your vehicle in real-time with live updates.",
    ),
    IntroPage(
      title: "Get Notifications",
      description: "Receive timely notifications about your vehicle status.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background color for the whole intro screen (optional)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade900, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // PageView for content
          PageView(
            controller: _pageController,
            onPageChanged: (int index) {
              setState(() {
                currentPage = index;
              });
            },
            children: pages,
          ),
          // Positioned buttons and indicators at the bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    // Skip and go to the Login screen
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text(
                    "Skip",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Row(
                  children: List.generate(
                    pages.length,
                    (index) => Icon(
                      index == currentPage
                          ? Icons.circle
                          : Icons.circle_outlined,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Navigate to the next page, or finish and navigate to login
                    if (currentPage < pages.length - 1) {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.ease,
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    }
                  },
                  child: Text(
                    currentPage == pages.length - 1 ? "Finish" : "Next",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class IntroPage extends StatelessWidget {
  final String title;
  final String description;

  const IntroPage({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Optionally, you can add some padding or decoration if needed here
        SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 10),
        Text(
          description,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}
