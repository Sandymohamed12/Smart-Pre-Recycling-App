import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';
import '../../services/user_session.dart';

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
  bool isSaving = false;

  String? result;
  String? confidence;
  String? recommendation;
  String? saveMessage;

  double weight = 1.0;

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
        confidence = null;
        recommendation = null;
        saveMessage = null;
      });

      await _fakeClassification();
    } catch (e) {
      _showSnackBar("Failed to pick image");
    }
  }

  Future<void> _fakeClassification() async {
    setState(() {
      isProcessing = true;
      saveMessage = null;
    });

    await Future.delayed(const Duration(seconds: 2));

    final categories = ["plastic", "glass", "metal", "organic"];
    final random = Random();
    final selected = categories[random.nextInt(categories.length)];
    final conf = (0.80 + random.nextDouble() * 0.19).toStringAsFixed(2);

    setState(() {
      result = selected;
      confidence = conf;
      recommendation = _buildRecommendation(selected);
      isProcessing = false;
    });
  }

  String _buildRecommendation(String type) {
    switch (type.toLowerCase()) {
      case "plastic":
        return "Rinse the item and dispose of it in the plastic recycling bin.";
      case "glass":
        return "Remove any lids if possible and place it in the glass recycling bin.";
      case "metal":
        return "Clean the item and place it in the metal recycling bin.";
      case "organic":
        return "Dispose of it in the organic waste or compost bin if available.";
      default:
        return "Dispose of the item in the correct recycling bin.";
    }
  }

  Future<void> _saveScan() async {
    if (result == null) {
      _showSnackBar("Please scan an item first");
      return;
    }

    if (UserSession.backendUserId == null) {
      _showSnackBar("User session not found");
      return;
    }

    setState(() {
      isSaving = true;
      saveMessage = null;
    });

    try {
      await ApiService.createScan(
        userId: UserSession.backendUserId!,
        materialType: result!,
        weight: weight,
      );

      setState(() {
        isSaving = false;
        saveMessage = "Scan saved successfully ✅";
      });

      _showSnackBar("Scan saved to backend");
    } catch (e) {
      setState(() {
        isSaving = false;
        saveMessage = "Failed to save scan";
      });

      _showSnackBar("Error saving scan");
    }
  }

  Color _typeColor(String type) {
    switch (type.toLowerCase()) {
      case "plastic":
        return Colors.blue;
      case "glass":
        return Colors.green;
      case "metal":
        return Colors.orange;
      case "organic":
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case "plastic":
        return Icons.local_drink;
      case "glass":
        return Icons.wine_bar_outlined;
      case "metal":
        return Icons.hardware;
      case "organic":
        return Icons.compost;
      default:
        return Icons.recycling;
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
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.green.shade100),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_outlined,
              size: 60,
              color: Colors.green.shade300,
            ),
            const SizedBox(height: 12),
            const Text(
              "No image selected yet",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Use the camera or gallery to start scanning",
              style: TextStyle(
                fontSize: 13,
                color: Colors.black45,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: kIsWeb
          ? (webImageBytes != null
              ? Image.memory(
                  webImageBytes!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                )
              : const Center(child: Text("Unable to preview image")))
          : Image.network(
              selectedImage!.path,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) {
                return const Center(child: Text("Unable to preview image"));
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanColor = result != null ? _typeColor(result!) : Colors.green;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Smart Scan"),
        backgroundColor: const Color(0xFF7CB342),
      ),
      backgroundColor: const Color(0xFFF1F8E9),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade700,
                  Colors.green.shade500,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI-Powered Waste Scan",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Capture or upload an item to classify its material and save the recycling result.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          _buildImagePreview(),
          const SizedBox(height: 18),

          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isProcessing ? null : pickFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isProcessing ? null : pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text("Gallery"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade700,
                    side: BorderSide(color: Colors.green.shade700),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Estimated Weight",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "${weight.toStringAsFixed(1)} kg",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Slider(
                  value: weight,
                  min: 0.5,
                  max: 5.0,
                  divisions: 9,
                  label: weight.toStringAsFixed(1),
                  activeColor: Colors.green,
                  onChanged: (value) {
                    setState(() => weight = value);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          if (isProcessing)
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 14),
                  Text(
                    "Analyzing item...",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Please wait while the classification is being generated.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),

          if (!isProcessing && result != null) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: scanColor.withOpacity(0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: scanColor.withOpacity(0.15),
                        child: Icon(
                          _typeIcon(result!),
                          color: scanColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          result!.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: scanColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${((double.tryParse(confidence ?? "0") ?? 0) * 100).toStringAsFixed(0)}%",
                          style: TextStyle(
                            color: scanColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _resultRow("Classification", result!.toUpperCase()),
                  _resultRow("Confidence", confidence ?? "-"),
                  _resultRow("Estimated Weight", "${weight.toStringAsFixed(1)} kg"),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline, color: scanColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            recommendation ?? "",
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _saveScan,
                icon: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(isSaving ? "Saving..." : "Save Scan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ],

          if (saveMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: saveMessage!.contains("success")
                    ? Colors.green.withOpacity(0.12)
                    : Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    saveMessage!.contains("success")
                        ? Icons.check_circle
                        : Icons.error_outline,
                    color: saveMessage!.contains("success")
                        ? Colors.green
                        : Colors.red,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      saveMessage!,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "This version uses temporary classification logic to demonstrate the full workflow until AI model integration is finalized.",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _resultRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}