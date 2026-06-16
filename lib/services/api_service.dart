import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static String get baseUrl {
    return kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";
  }

  // =========================
  // 🔹 Sync User
  // =========================
  static Future<Map<String, dynamic>> syncUser({
    required String firebaseUid,
    required String email,
    required String name,
  }) async {
    final url = Uri.parse("$baseUrl/users/sync");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "firebase_uid": firebaseUid,
        "email": email,
        "name": name,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to sync user: ${response.body}");
    }
  }

  // =========================
  // 🔹 Get User By Id
  // =========================
  static Future<Map<String, dynamic>> getUserById(int userId) async {
    final url = Uri.parse("$baseUrl/users/$userId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load user: ${response.body}");
    }
  }

  // =========================
  // 🔹 Update User Name
  // =========================
  static Future<Map<String, dynamic>> updateUser({
    required int userId,
    required String name,
  }) async {
    final url = Uri.parse("$baseUrl/users/$userId");

    final response = await http.put(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to update user: ${response.body}");
    }
  }

// =========================
// 🔹 Create Scan
// =========================
static Future<Map<String, dynamic>> createScan({
  required int userId,
  required String materialType,
  required bool recyclable,
}) async {
  final url = Uri.parse("$baseUrl/scans/");

  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
    },
    body: jsonEncode({
      "user_id": userId,
      "material_type": materialType,
      "recyclable": recyclable,
    }),
  );

  if (response.statusCode == 200 ||
      response.statusCode == 201) {
    return jsonDecode(response.body);
  } else {
    throw Exception(
      "Failed to create scan: ${response.body}",
    );
  }
}
  // =========================
// 🔹 Get User Scans
// =========================
static Future<List<dynamic>> getUserScans(
  int userId,
) async {
  final url = Uri.parse(
    "$baseUrl/scans/user/$userId",
  );

  final response = await http.get(url);

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception(
      "Failed to load scans",
    );
  }
}

// =========================
// 🔹 Delete Scan
// =========================
static Future<void> deleteScan(
  int scanId,
) async {
  final url = Uri.parse(
    "$baseUrl/scans/$scanId",
  );

  final response = await http.delete(url);

  if (response.statusCode != 200) {
    throw Exception(
      "Failed to delete scan",
    );
  }
}

  // =========================
  // 🔥 AI Prediction (FIXED FOR WEB)
  // =========================
  static Future<Map<String, dynamic>> uploadImage(
    String filePath, {
    Uint8List? webBytes,
  }) async {
    final url = Uri.parse("$baseUrl/predict");

    var request = http.MultipartRequest('POST', url);

    if (kIsWeb) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          webBytes!,
          filename: "image.jpg",
        ),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath('file', filePath),
      );
    }

    var response = await request.send();
    var responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseData);
    } else {
      throw Exception("Prediction failed: $responseData");
    }
  }
}