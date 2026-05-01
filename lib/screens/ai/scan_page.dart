import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final ImagePicker picker = ImagePicker();

  XFile? selectedImage;
  Uint8List? webImageBytes;

  bool isProcessing = false;

  String? result;
  String? recommendation;
  List<dynamic>? detections;
  bool? isRecyclable;

  Future<void> pickFromCamera() async {
    await _pickImage(ImageSource.camera);
  }

  Future<void> pickFromGallery() async {
    await _pickImage(ImageSource.gallery);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (picked == null) return;

      Uint8List? bytes;
      if (kIsWeb) {
        bytes = await picked.readAsBytes();
      }

      setState(() {
        selectedImage = picked;
        webImageBytes = bytes;
        result = null;
        recommendation = null;
        detections = null;
        isRecyclable = null;
      });

      await _realClassification();
    } catch (e) {
      _showSnackBar("Failed to pick image");
    }
  }

  Future<void> _realClassification() async {
    if (selectedImage == null) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final response = await ApiService.uploadImage(
        selectedImage!.path,
        webBytes: webImageBytes,
      );

      print("AI RESULT: $response");

      final recyclable = response["recyclable"];
      final category = response["category"];
      final dets = response["detections"];

      String recText;

      if (recyclable == true) {
        recText = "Item is recyclable. Dispose correctly.";
      } else {
        recText = "This item cannot be recycled.";
      }

      setState(() {
        isRecyclable = recyclable;
        result = category;
        recommendation = recText;
        detections = dets;
        isProcessing = false;
      });
    } catch (e) {
      setState(() {
        isProcessing = false;
      });

      _showSnackBar("Error connecting to AI backend");
      print("ERROR: $e");
    }
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  Widget _buildImagePreview() {
    if (selectedImage == null) {
      return Container(
        height: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: Text("No image selected")),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: kIsWeb
          ? Image.memory(webImageBytes!, height: 240, fit: BoxFit.cover)
          : Image.network(selectedImage!.path,
              height: 240, fit: BoxFit.cover),
    );
  }

  // =========================
  // 🎯 BEAUTIFUL RESULT CARD
  // =========================
  Widget _buildResultCard() {
    if (result == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ♻️ Recyclability Badge
          Row(
            children: [
              Icon(
                isRecyclable == true ? Icons.check_circle : Icons.cancel,
                color: isRecyclable == true ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(
                isRecyclable == true ? "Recyclable" : "Not Recyclable",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color:
                      isRecyclable == true ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // 📦 Category
          Text(
            "Category",
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 5),
          Text(
            result!,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          // 💡 Recommendation
          Text(
            recommendation ?? "",
            style: const TextStyle(fontSize: 15),
          ),

          // 🔍 Detections
          if (detections != null && detections!.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 10),

            const Text(
              "Detected Objects",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 10),

            ...detections!.map((det) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(det["label"]),
                    Text(
                      "${(det["confidence"] * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Scan"),
        backgroundColor: const Color(0xFF7CB342),
      ),
      backgroundColor: const Color(0xFFF1F8E9),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildImagePreview(),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isProcessing ? null : pickFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isProcessing ? null : pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text("Gallery"),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (isProcessing)
            const Center(child: CircularProgressIndicator()),

          if (!isProcessing) _buildResultCard(),
        ],
      ),
    );
  }
}