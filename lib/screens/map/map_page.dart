import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  List<Marker> markers = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchCenters();
  }

  Future<void> fetchCenters() async {
    final baseUrl = kIsWeb
        ? "http://127.0.0.1:8000"
        : "http://10.0.2.2:8000";

    try {
      final response = await http.get(
        Uri.parse("$baseUrl/centers/"),
      );

      print("Status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final List centers = jsonDecode(response.body);

        final List<Marker> loadedMarkers = centers.map((center) {
          final lat = (center["latitude"] as num).toDouble();
          final lng = (center["longitude"] as num).toDouble();
          final name = center["name"] ?? "Recycling Center";
          final type = center["type"] ?? "unknown";

          return Marker(
            point: LatLng(lat, lng),
            width: 80,
            height: 80,
            child: Tooltip(
              message: "$name\nType: $type",
              child: const Icon(
                Icons.location_on,
                color: Colors.red,
                size: 45,
              ),
            ),
          );
        }).toList();

        setState(() {
          markers = loadedMarkers;
          isLoading = false;
          errorMessage = null;
        });

        print("Markers count: ${markers.length}");
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "Failed to load centers";
        });
      }
    } catch (e) {
      print("Error fetching centers: $e");
      setState(() {
        isLoading = false;
        errorMessage = "Error fetching centers: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const LatLng cairo = LatLng(30.0444, 31.2357);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Where to Recycle"),
        backgroundColor: const Color(0xFF7CB342),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              : FlutterMap(
                  options: const MapOptions(
                    initialCenter: cairo,
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      userAgentPackageName:
                          'com.example.smart_pre_recycling',
                    ),
                    MarkerLayer(
                      markers: markers,
                    ),
                  ],
                ),
    );
  }
}