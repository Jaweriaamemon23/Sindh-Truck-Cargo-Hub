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
    const IntroPage(
      title: "Vehicle Type",
      description: "Select your vehicle according to your requirement",
    ),
    const IntroPage(
      title: "Track Your Vehicle",
      description: "Track your vehicle in real-time with live updates.",
    ),
    const IntroPage(
      title: "Get Notifications",
      description: "Receive timely notifications about your vehicle status.",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
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
          PageView.builder(
            controller: _pageController,
            itemCount: pages.length,
            onPageChanged: (index) {
              setState(() {
                currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return pages[index];
            },
          ),

          // Positioned controls at the bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Skip Button
                if (currentPage != pages.length - 1)
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child: const Text(
                      "Skip",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  )
                else
                  const SizedBox(width: 60), // Placeholder for alignment

                // Page Indicator Dots
                Row(
                  children: List.generate(
                    pages.length,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        Icons.circle,
                        color: index == currentPage
                            ? Colors.white
                            : Colors.white70,
                        size: index == currentPage ? 12 : 10,
                      ),
                    ),
                  ),
                ),

                // Next or Finish Button
                TextButton(
                  onPressed: () {
                    if (currentPage < pages.length - 1) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
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
                    style: const TextStyle(color: Colors.white, fontSize: 16),
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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
