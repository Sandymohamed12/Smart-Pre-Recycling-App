import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../services/user_session.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  final PageController _pageController = PageController();
  Timer? _timer;

  int _currentPage = 0;
  bool isLoading = true;
  String? errorMessage;

  int totalScans = 0;
  double totalCo2Saved = 0.0;

  int plasticCount = 0;
  int glassCount = 0;
  int metalCount = 0;
  int organicCount = 0;

  List<dynamic> recentScans = [];

  final List<String> images = const [
    "assets/images/recycle2.png",
    "assets/images/recycle3.png",
    "assets/images/recycle4.png",
  ];

  String get baseUrl =>
      kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";

  @override
  void initState() {
    super.initState();
    _startSlider();
    loadDashboardData();
  }

  void _startSlider() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % images.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> loadDashboardData() async {
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

      final userResponse = await http.get(
        Uri.parse("$baseUrl/users/${UserSession.backendUserId}"),
      );

      final scansResponse = await http.get(
        Uri.parse("$baseUrl/scans/user/${UserSession.backendUserId}"),
      );

      if (userResponse.statusCode != 200 || scansResponse.statusCode != 200) {
        setState(() {
          isLoading = false;
          errorMessage = "Failed to load dashboard data";
        });
        return;
      }

      final userData = jsonDecode(userResponse.body);
      final List scansData = jsonDecode(scansResponse.body);

      int plastic = 0;
      int glass = 0;
      int metal = 0;
      int organic = 0;

      for (final scan in scansData) {
        final type = scan["material_type"].toString().toLowerCase();
        if (type == "plastic") plastic++;
        if (type == "glass") glass++;
        if (type == "metal") metal++;
        if (type == "organic") organic++;
      }

      setState(() {
        totalScans = userData["total_scans"] ?? 0;
        totalCo2Saved = (userData["total_co2_saved"] ?? 0).toDouble();

        plasticCount = plastic;
        glassCount = glass;
        metalCount = metal;
        organicCount = organic;

        recentScans = scansData.reversed.take(3).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error loading dashboard";
      });
    }
  }

  Future<void> _generatePDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              "Smart Pre-Recycling Report",
              style: const pw.TextStyle(fontSize: 22),
            ),
            pw.SizedBox(height: 20),
            pw.Text("Total Items Recycled: $totalScans"),
            pw.Text("Total CO₂ Saved: ${totalCo2Saved.toStringAsFixed(2)} kg"),
            pw.SizedBox(height: 12),
            pw.Text("Material Distribution:"),
            pw.Text("Plastic: $plasticCount"),
            pw.Text("Glass: $glassCount"),
            pw.Text("Metal: $metalCount"),
            pw.Text("Organic: $organicCount"),
            pw.SizedBox(height: 18),
            pw.Text(
              "Your recycling actions contribute to reducing waste and supporting environmental sustainability.",
            ),
          ],
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File("${dir.path}/recycling_report.pdf");
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: "My Smart Pre-Recycling Report 🌱",
    );
  }

  int get _maxMaterialValue {
    final maxValue = [
      plasticCount,
      glassCount,
      metalCount,
      organicCount,
    ].reduce((a, b) => a > b ? a : b);

    return maxValue == 0 ? 1 : maxValue;
  }

  double get _chartTotal =>
      (plasticCount + glassCount + metalCount + organicCount).toDouble();

  List<PieChartSectionData> _pieSections() {
    if (_chartTotal == 0) {
      return [
        PieChartSectionData(
          value: 1,
          radius: 50,
          title: "No Data",
          color: Colors.grey.shade400,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ];
    }

    return [
      PieChartSectionData(
        value: plasticCount.toDouble(),
        title: "Plastic",
        radius: 52,
        color: Colors.blue,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
      PieChartSectionData(
        value: glassCount.toDouble(),
        title: "Glass",
        radius: 52,
        color: Colors.green,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
      PieChartSectionData(
        value: metalCount.toDouble(),
        title: "Metal",
        radius: 52,
        color: Colors.orange,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
      PieChartSectionData(
        value: organicCount.toDouble(),
        title: "Organic",
        radius: 52,
        color: Colors.brown,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    ];
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final firstName = user?.email?.split("@").first ?? "User";

    return RefreshIndicator(
      onRefresh: loadDashboardData,
      child: isLoading
          ? ListView(
              children: [
                SizedBox(height: 250),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : errorMessage != null
              ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 120),
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade400,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: loadDashboardData,
                      child: const Text("Retry"),
                    ),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    SizedBox(
                      height: 250,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: images.length,
                        onPageChanged: (i) {
                          setState(() => _currentPage = i);
                        },
                        itemBuilder: (_, index) {
                          return AnimatedBuilder(
                            animation: _pageController,
                            builder: (context, child) {
                              double value = 1.0;
                              if (_pageController.hasClients &&
                                  _pageController.position.haveDimensions) {
                                value = (_pageController.page! - index).abs();
                                value = (1 - (value * 0.15)).clamp(0.85, 1.0);
                              }
                              return Transform.scale(scale: value, child: child);
                            },
                            child: Stack(
                              children: [
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    image: DecorationImage(
                                      image: AssetImage(images[index]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.black.withOpacity(0.60),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 20,
                                  right: 20,
                                  bottom: 24,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Welcome back, $firstName 👋",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        "Track your recycling impact and keep making a difference.",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentPage == i ? 16 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                _currentPage == i ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: _summaryCard(
                            title: "Total Scans",
                            value: "$totalScans",
                            icon: Icons.recycling,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _summaryCard(
                            title: "CO₂ Saved",
                            value: "${totalCo2Saved.toStringAsFixed(2)} kg",
                            icon: Icons.eco,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      "Material Distribution",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
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
                        children: [
                          SizedBox(
                            height: 220,
                            child: PieChart(
                              PieChartData(
                                sections: _pieSections(),
                                centerSpaceRadius: 40,
                                sectionsSpace: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          _statBar("Plastic", plasticCount, Colors.blue),
                          _statBar("Glass", glassCount, Colors.green),
                          _statBar("Metal", metalCount, Colors.orange),
                          _statBar("Organic", organicCount, Colors.brown),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      "Recent Activity",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (recentScans.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "No scans yet. Start recycling to see your activity here.",
                          style: TextStyle(fontSize: 15),
                        ),
                      )
                    else
                      ...recentScans.map(
                        (scan) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFE8F5E9),
                              child: Icon(Icons.recycling, color: Colors.green),
                            ),
                            title: Text(
                              scan["material_type"]
                                  .toString()
                                  .toUpperCase(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "Weight: ${scan["weight"]} kg • CO₂: ${scan["co2_saved"]}",
                            ),
                            trailing: Text(
                              scan["created_at"].toString().substring(0, 10),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf),
                        label: const Text("Generate PDF Report"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _generatePDF,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
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
        children: [
          Icon(icon, color: Colors.green.shade700, size: 30),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _statBar(String label, int value, Color color) {
    final progress = value / _maxMaterialValue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label ($value items)",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            builder: (_, v, __) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: v,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade300,
                  color: color,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}