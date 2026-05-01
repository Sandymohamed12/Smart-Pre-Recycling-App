import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/user_session.dart';

class DashboardStats extends StatefulWidget {
  const DashboardStats({super.key});

  @override
  State<DashboardStats> createState() => _DashboardStatsState();
}

class _DashboardStatsState extends State<DashboardStats>
    with SingleTickerProviderStateMixin {
  bool isLoading = true;
  String? errorMessage;

  int totalScans = 0;
  double totalCo2 = 0.0;

  int plastic = 0;
  int glass = 0;
  int metal = 0;
  int organic = 0;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  String get baseUrl =>
      kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    fetchStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchStats() async {
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
          errorMessage = "Failed to load statistics";
        });
        return;
      }

      final userData = jsonDecode(userResponse.body);
      final List scans = jsonDecode(scansResponse.body);

      int plasticCount = 0;
      int glassCount = 0;
      int metalCount = 0;
      int organicCount = 0;

      for (final scan in scans) {
        final type = scan["material_type"].toString().toLowerCase();

        if (type == "plastic") plasticCount++;
        if (type == "glass") glassCount++;
        if (type == "metal") metalCount++;
        if (type == "organic") organicCount++;
      }

      setState(() {
        totalScans = userData["total_scans"] ?? 0;
        totalCo2 = (userData["total_co2_saved"] ?? 0).toDouble();

        plastic = plasticCount;
        glass = glassCount;
        metal = metalCount;
        organic = organicCount;

        isLoading = false;
      });

      _animationController.forward(from: 0);
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error loading statistics";
      });
    }
  }

  int get highestCategoryValue {
    final maxValue = [plastic, glass, metal, organic]
        .reduce((a, b) => a > b ? a : b);
    return maxValue == 0 ? 1 : maxValue;
  }

  String get topCategory {
    final map = {
      "Plastic": plastic,
      "Glass": glass,
      "Metal": metal,
      "Organic": organic,
    };

    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.first.value == 0) return "No data yet";
    return sorted.first.key;
  }

  Color getCategoryColor(String label) {
    switch (label.toLowerCase()) {
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

  IconData getCategoryIcon(String label) {
    switch (label.toLowerCase()) {
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

  List<PieChartSectionData> buildPieSections() {
    final total = plastic + glass + metal + organic;

    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          title: "No Data",
          radius: 58,
          color: Colors.grey.shade400,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ];
    }

    return [
      PieChartSectionData(
        value: plastic.toDouble(),
        title: "Plastic",
        radius: 58,
        color: Colors.blue,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      PieChartSectionData(
        value: glass.toDouble(),
        title: "Glass",
        radius: 58,
        color: Colors.green,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      PieChartSectionData(
        value: metal.toDouble(),
        title: "Metal",
        radius: 58,
        color: Colors.orange,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      PieChartSectionData(
        value: organic.toDouble(),
        title: "Organic",
        radius: 58,
        color: Colors.brown,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: fetchStats,
      child: isLoading
          ? ListView(
              children: const [
                SizedBox(height: 220),
                Center(child: CircularProgressIndicator()),
              ],
            )
          : errorMessage != null
              ? ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 140),
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 18),
                  ],
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 18),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.08,
                          children: [
                            _buildSummaryCard(
                              title: "Total Scans",
                              value: "$totalScans",
                              icon: Icons.recycling,
                              color: Colors.green,
                            ),
                            _buildSummaryCard(
                              title: "CO₂ Saved",
                              value: totalCo2.toStringAsFixed(2),
                              icon: Icons.eco,
                              color: Colors.teal,
                            ),
                            _buildSummaryCard(
                              title: "Top Category",
                              value: topCategory,
                              icon: Icons.emoji_events_outlined,
                              color: Colors.orange,
                            ),
                            _buildSummaryCard(
                              title: "Scan Efficiency",
                              value: totalScans == 0
                                  ? "0%"
                                  : "${((totalCo2 / totalScans) * 100).toStringAsFixed(0)}%",
                              icon: Icons.trending_up,
                              color: Colors.purple,
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle("Recycling Breakdown"),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
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
                                height: 240,
                                child: PieChart(
                                  PieChartData(
                                    centerSpaceRadius: 46,
                                    sectionsSpace: 3,
                                    sections: buildPieSections(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              _buildProgressTile("Plastic", plastic),
                              _buildProgressTile("Glass", glass),
                              _buildProgressTile("Metal", metal),
                              _buildProgressTile("Organic", organic),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle("Material Summary"),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
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
                              _buildMaterialRow("Plastic", plastic),
                              const SizedBox(height: 12),
                              _buildMaterialRow("Glass", glass),
                              const SizedBox(height: 12),
                              _buildMaterialRow("Metal", metal),
                              const SizedBox(height: 12),
                              _buildMaterialRow("Organic", organic),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle("Insights"),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade700,
                                Colors.green.shade500,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.auto_graph, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    "Performance Insight",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                totalScans == 0
                                    ? "Start scanning items to generate your recycling analytics."
                                    : "You have completed $totalScans scans and saved ${totalCo2.toStringAsFixed(2)} kg of CO₂. Your top recycled category is $topCategory.",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
            "Your Recycling Statistics",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Track your scan activity, material distribution, and environmental impact.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1),
      duration: const Duration(milliseconds: 450),
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTile(String label, int value) {
    final progress = value / highestCategoryValue;
    final color = getCategoryColor(label);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(getCategoryIcon(label), color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                "$value",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 900),
            builder: (_, animatedValue, __) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: animatedValue,
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

  Widget _buildMaterialRow(String label, int value) {
    final color = getCategoryColor(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(
              getCategoryIcon(label),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
          Text(
            "$value items",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}