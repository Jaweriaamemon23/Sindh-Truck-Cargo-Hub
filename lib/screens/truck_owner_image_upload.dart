import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class TruckOwnerImageUpload extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> formData;

  const TruckOwnerImageUpload({
    required this.userId,
    required this.formData,
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
  double _uploadProgress = 0.0; // Track upload progress

  /// **🔥 Pick an Image from File Picker**
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

  /// **🔥 Upload Images and Save Data to Firestore**
  Future<void> _uploadImages() async {
    if (_nicFrontImage == null ||
        _nicBackImage == null ||
        _vehicleImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("⚠️ Please upload all images before submitting.")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final storage = FirebaseStorage.instance;
      final firestore = FirebaseFirestore.instance;
      Map<String, String> imageUrls = {};

      // **🔥 Upload Images and Track Progress**
      imageUrls['nicFrontUrl'] =
          await _uploadImage(storage, _nicFrontImage!, 'nic_front');
      imageUrls['nicBackUrl'] =
          await _uploadImage(storage, _nicBackImage!, 'nic_back');
      imageUrls['vehicleUrl'] =
          await _uploadImage(storage, _vehicleImage!, 'vehicle');

      // **🔥 Merge Form Data with Image URLs**
      final userData = {
        ...widget.formData, // Truck Owner Form Data
        ...imageUrls, // Uploaded Image URLs
      };

      // **🔥 Save Data to Firestore**
      await firestore.collection('users').doc(widget.userId).set(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Registration completed successfully!")),
      );

      // **🔥 Navigate to Login Page**
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      print("🔥 Error uploading images: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error uploading images: $e")),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// **🔥 Upload Image to Firebase Storage with Progress Tracking**
  Future<String> _uploadImage(
      FirebaseStorage storage, Uint8List imageData, String path) async {
    Reference ref = storage.ref().child('$path/${widget.userId}.jpg');
    UploadTask uploadTask = ref.putData(imageData);

    // Track Progress
    uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
      setState(() {
        _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
      });
    });

    await uploadTask;
    return await ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueAccent.shade100,
      appBar: AppBar(
        title: const Text("Upload NIC & Vehicle Images"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 10,
            shadowColor: Colors.blueAccent.shade200,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    "Upload Required Documents",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _imagePickerButton("NIC Front", "NIC_Front", _nicFrontImage),
                  _imagePickerButton("NIC Back", "NIC_Back", _nicBackImage),
                  _imagePickerButton("Vehicle Image", "Vehicle", _vehicleImage),
                  const SizedBox(height: 30),
                  _isUploading
                      ? Column(
                          children: [
                            LinearProgressIndicator(
                                value: _uploadProgress,
                                backgroundColor: Colors.grey.shade300,
                                color: Colors.blueAccent),
                            const SizedBox(height: 10),
                            Text(
                              "Uploading... ${(100 * _uploadProgress).toStringAsFixed(0)}%",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent),
                            ),
                          ],
                        )
                      : ElevatedButton(
                          onPressed: _uploadImages,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Submit",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// **🔥 Image Picker UI Component**
  Widget _imagePickerButton(String label, String type, Uint8List? image) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => _pickImage(type),
          icon: const Icon(Icons.camera_alt, color: Colors.white),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent.shade700,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          ),
        ),
        const SizedBox(height: 8),
        if (image != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child:
                Image.memory(image, height: 100, width: 150, fit: BoxFit.cover),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}
