import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:http/http.dart' as http; // For making HTTP requests
import 'dart:convert'; // For JSON encoding and decoding

class GoogleAuthService {
  final String apiKey =
      dotenv.env['GOOGLE_API_KEY'] ?? ''; // Retrieve from .env file

  // Request OTP using Google's Identity Toolkit
  Future<String?> requestOtp(String phoneNumber) async {
    final url =
        'https://identitytoolkit.googleapis.com/v1/accounts:sendVerificationCode?key=$apiKey';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'recaptchaToken':
              'dummy-recaptcha-token', // Use a real reCAPTCHA token
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('OTP sent successfully: $data');
        return data[
            'sessionInfo']; // Return sessionInfo to use in OTP verification
      } else {
        print('Failed to send OTP: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error requesting OTP: $e');
      return null;
    }
  }

  // Verify OTP with sessionInfo and code
  Future<bool> verifyOtp(String sessionInfo, String otp) async {
    final url =
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPhoneNumber?key=$apiKey';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sessionInfo': sessionInfo,
          'code': otp,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('User verified successfully: $data');
        return true; // OTP verification successful
      } else {
        print('Failed to verify OTP: ${response.body}');
        return false; // OTP verification failed
      }
    } catch (e) {
      print('Error verifying OTP: $e');
      return false;
    }
  }
}
