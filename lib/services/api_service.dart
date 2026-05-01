import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

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
    required double weight,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    final idToken = await user.getIdToken();

    final url = Uri.parse("$baseUrl/scans/");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $idToken",
      },
      body: jsonEncode({
        "user_id": userId,
        "material_type": materialType,
        "weight": weight,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to create scan: ${response.body}");
    }
  }

  // =========================
  // 🔹 Get User Scans (History)
  // =========================
  static Future<List<dynamic>> getUserScans(int userId) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception("User not logged in");
    }

    final idToken = await user.getIdToken();

    final url = Uri.parse("$baseUrl/scans/user/$userId");

    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $idToken",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load history: ${response.body}");
    }
  }
}