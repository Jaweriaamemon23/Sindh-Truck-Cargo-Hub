import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cloudinary_service.dart';
import 'login_screen.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';

class TruckOwnerImageUpload extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> formData;
  final String truckOwnerDocId; // The document ID to update

  const TruckOwnerImageUpload({
    required this.userId,
    required this.formData,
    required this.truckOwnerDocId,
    Key? key,
  }) : super(key: key);

  @override
  _TruckOwnerImageUploadState createState() => _TruckOwnerImageUploadState();
}

class _TruckOwnerImageUploadState extends State<TruckOwnerImageUpload> {
  Uint8List? _nicFrontImage;
  Uint8List? _nicBackImage;
  Uint8List? _vehicleImage;
  bool _isUploading = false;

  Future<void> _pickImage(String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        if (type == "NIC_Front") {
          _nicFrontImage = result.files.single.bytes;
        } else if (type == "NIC_Back") {
          _nicBackImage = result.files.single.bytes;
        } else if (type == "Vehicle") {
          _vehicleImage = result.files.single.bytes;
        }
      });
    }
  }

  Future<void> _uploadImages() async {
    if (_nicFrontImage == null ||
        _nicBackImage == null ||
        _vehicleImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please upload all images.")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Upload images to Cloudinary
      String? nicFrontUrl =
          await CloudinaryService().uploadImage(_nicFrontImage!);
      String? nicBackUrl =
          await CloudinaryService().uploadImage(_nicBackImage!);
      String? vehicleUrl =
          await CloudinaryService().uploadImage(_vehicleImage!);

      if (nicFrontUrl != null && nicBackUrl != null && vehicleUrl != null) {
        Map<String, String> imageUrls = {
          'nicFrontUrl': nicFrontUrl,
          'nicBackUrl': nicBackUrl,
          'vehicleUrl': vehicleUrl,
        };

        // Merge form data with image URLs
        final userData = {
          ...widget.formData,
          ...imageUrls,
          'isCompleted': true, // Mark registration as completed
        };

        // Save data to Firestore under the existing truckOwnerDocId
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('truckOwners')
            .doc(widget.truckOwnerDocId)
            .update(userData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("✅ Registration completed successfully!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        print("❌ Failed to upload one or more images.");
      }
    } catch (e) {
      print("❌ Error uploading images: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSindhi = Provider.of<LanguageProvider>(context).isSindhi;

    return Scaffold(
      appBar: AppBar(title: Text(isSindhi ? "تصویریں اپ لوڈ کریں" : "Upload Truck Owner Images")),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildImagePicker(
                  isSindhi ? "این آئی سی فرنٹ اپ لوڈ کریں" : "Upload NIC Front", "NIC_Front", _nicFrontImage),
              _buildImagePicker(isSindhi ? "این آئی سی بیک اپ لوڈ کریں" : "Upload NIC Back", "NIC_Back", _nicBackImage),
              _buildImagePicker(
                  isSindhi ? "گاڑی کی تصویر اپ لوڈ کریں" : "Upload Vehicle Image", "Vehicle", _vehicleImage),
              _isUploading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _uploadImages,
                      child: Text(isSindhi ? "تصویریں اپ لوڈ کریں" : "Upload Images"),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(String label, String type, Uint8List? image) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _pickImage(type),
          child: Text(label),
        ),
        if (image != null)
          Image.memory(image, height: 100, width: 100, fit: BoxFit.cover),
        SizedBox(height: 10),
      ],
    );
  }
}
