import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/user_session.dart';

class DashboardHistory extends StatefulWidget {
  const DashboardHistory({super.key});

  @override
  State<DashboardHistory> createState() => _DashboardHistoryState();
}

class _DashboardHistoryState extends State<DashboardHistory> {
  List scans = [];
  bool isLoading = true;
  String? errorMessage;

  String get baseUrl =>
      kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      if (UserSession.backendUserId == null) {
        setState(() {
          isLoading = false;
          errorMessage = "User session not found";
        });
        return;
      }

      final response = await http.get(
        Uri.parse("$baseUrl/scans/user/${UserSession.backendUserId}"),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        setState(() {
          scans = data.reversed.toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Failed to load history";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error loading history";
      });
    }
  }

  Color getColor(String type) {
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

  IconData getIcon(String type) {
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

  String formatDate(String date) {
    if (date.length >= 10) {
      return date.substring(0, 10);
    }
    return date;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            errorMessage!,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (scans.isEmpty) {
      return RefreshIndicator(
        onRefresh: fetchHistory,
        child: ListView(
          children: const [
            SizedBox(height: 220),
            Center(
              child: Text(
                "No scans yet ♻️",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: fetchHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: scans.length,
        itemBuilder: (context, index) {
          final scan = scans[index];
          final type = scan["material_type"].toString();
          final weight = scan["weight"];
          final co2 = scan["co2_saved"];
          final date = formatDate(scan["created_at"].toString());

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                colors: [
                  getColor(type).withOpacity(0.15),
                  Colors.white,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: getColor(type),
                child: Icon(
                  getIcon(type),
                  color: Colors.white,
                ),
              ),
              title: Text(
                type.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Weight: $weight kg"),
                    const SizedBox(height: 4),
                    Text("CO₂ Saved: $co2"),
                  ],
                ),
              ),
              trailing: Text(
                date,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}