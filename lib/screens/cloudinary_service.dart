import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class CloudinaryService {
  final String cloudName = "dinlijmhh"; // Your Cloudinary cloud name
  final String apiKey = "398627791348945"; // Your Cloudinary API key
  final String uploadPreset = "ml_default"; // Your upload preset

  /// 🔥 **Upload Image to Cloudinary**
  Future<String?> uploadImage(Uint8List imageData) async {
    try {
      final String url =
          "https://api.cloudinary.com/v1_1/$cloudName/image/upload";
      print("🌐 Uploading to URL: $url"); // Debug print

      // Convert image data to base64
      String base64Image = base64Encode(imageData);
      print("📦 Image data encoded to base64."); // Debug print

      // Make the POST request to Cloudinary
      var response = await http.post(
        Uri.parse(url),
        body: {
          "file": "data:image/jpeg;base64,$base64Image",
          "upload_preset": uploadPreset,
          "api_key": apiKey,
        },
      );

      print("📥 Cloudinary response: ${response.statusCode}"); // Debug print
      print("📥 Cloudinary response body: ${response.body}"); // Debug print

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        print("✅ Upload successful: ${responseData['secure_url']}");
        return responseData['secure_url'];
      } else {
        print("❌ Cloudinary upload failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("❌ Error uploading to Cloudinary: $e");
      return null;
    }
  }
}
