import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

// Function to load environment variables from the JS context
void loadEnvVars() {
  final env = js.context['env']; // Accessing the env object
  if (env != null) {
    print('API_KEY: ${env['API_KEY']}');
    print('OTHER_VAR: ${env['OTHER_VAR']}');
  } else {
    print('Environment variables are not loaded!');
  }
}

void main() {
  loadEnvVars(); // Load environment variables
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Set SplashScreen as the initial screen
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false, // Optional: to remove the debug banner
    );
  }
}
