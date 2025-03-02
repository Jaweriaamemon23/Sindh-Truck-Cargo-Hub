import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  // Function to pick images
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

  // Function to upload images and save URLs to Firestore
  Future<void> _uploadImages() async {
    if (_nicFrontImage == null ||
        _nicBackImage == null ||
        _vehicleImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please upload all images before submitting.")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final storage = FirebaseStorage.instance;
      final firestore = FirebaseFirestore.instance;
      Map<String, String> imageUrls = {};

      // Upload images and get URLs
      imageUrls['nicFrontUrl'] =
          await _uploadImage(storage, _nicFrontImage!, 'nic_front');
      imageUrls['nicBackUrl'] =
          await _uploadImage(storage, _nicBackImage!, 'nic_back');
      imageUrls['vehicleUrl'] =
          await _uploadImage(storage, _vehicleImage!, 'vehicle');

      // Merge formData with image URLs
      final userData = {
        ...widget.formData,
        ...imageUrls,
      };

      // Save all data to Firestore
      await firestore.collection('users').doc(widget.userId).set(userData);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registration completed successfully!")),
      );

      // Navigate to the desired screen after successful upload
      // For example:
      // Navigator.pushReplacement(
      //   context,
      //   MaterialPageRoute(builder: (context) => TruckOwnerDashboard()),
      // );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading images: $e")),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // Helper function to upload a single image
  Future<String> _uploadImage(
      FirebaseStorage storage, Uint8List imageData, String path) async {
    Reference ref = storage.ref().child('$path/${widget.userId}.jpg');
    UploadTask uploadTask = ref.putData(imageData);
    await uploadTask.whenComplete(() => {});
    return await ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload NIC & Vehicle Images"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _imagePickerButton("Upload NIC Front", "NIC_Front"),
                  if (_nicFrontImage != null)
                    Image.memory(_nicFrontImage!, height: 100),
                  const SizedBox(height: 16),
                  _imagePickerButton("Upload NIC Back", "NIC_Back"),
                  if (_nicBackImage != null)
                    Image.memory(_nicBackImage!, height: 100),
                  const SizedBox(height: 16),
                  _imagePickerButton("Upload Vehicle Image", "Vehicle"),
                  if (_vehicleImage != null)
                    Image.memory(_vehicleImage!, height: 100),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _isUploading ? null : _uploadImages,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isUploading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Submit",
                            style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget for image picker button
  Widget _imagePickerButton(String label, String type) {
    return ElevatedButton.icon(
      onPressed: () => _pickImage(type),
      icon: const Icon(Icons.camera_alt),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
