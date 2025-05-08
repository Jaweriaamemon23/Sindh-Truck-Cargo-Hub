import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CloudinaryService {
  final String cloudName = "dinlijmhh";
  final String uploadPreset = "ml_default"; // Unsigned preset

  Future<String?> uploadImage(Uint8List imageData) async {
    try {
      final url =
          Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      if (kIsWeb) {
        // Web: Base64 Upload
        String base64Image = base64Encode(imageData);

        var response = await http.post(
          url,
          body: {
            "file": "data:image/jpeg;base64,$base64Image",
            "upload_preset": uploadPreset,
          },
        );

        if (response.statusCode == 200) {
          return json.decode(response.body)['secure_url'];
        } else {
          print("❌ Web upload failed: ${response.statusCode}");
          print(response.body);
          return null;
        }
      } else {
        // Mobile/Desktop: Multipart Upload
        var request = http.MultipartRequest("POST", url);
        request.fields['upload_preset'] = uploadPreset;
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            imageData,
            filename: 'upload.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );

        var response = await http.Response.fromStream(await request.send());
        if (response.statusCode == 200) {
          return json.decode(response.body)['secure_url'];
        } else {
          print("❌ Mobile upload failed: ${response.statusCode}");
          print(response.body);
          return null;
        }
      }
    } catch (e) {
      print("❌ Upload Exception: $e");
      return null;
    }
  }
}
