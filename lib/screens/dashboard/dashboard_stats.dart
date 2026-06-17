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
  int recyclableCount = 0;
  int nonRecyclableCount = 0;

  int plastic = 0;
  int glass = 0;
  int metal = 0;
  int organic = 0;
  int paper = 0;
  int other = 0;

  List<dynamic> scansList = [];

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

  bool _isRecyclable(dynamic value) {
    return value == true ||
        value == 1 ||
        value.toString().toLowerCase() == "true";
  }

  DateTime? _scanDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
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

      final scansResponse = await http.get(
        Uri.parse("$baseUrl/scans/user/${UserSession.backendUserId}"),
      );

      if (scansResponse.statusCode != 200) {
        setState(() {
          isLoading = false;
          errorMessage = "Failed to load statistics";
        });
        return;
      }

      final List scans = jsonDecode(scansResponse.body);

      int plasticCount = 0;
      int glassCount = 0;
      int metalCount = 0;
      int organicCount = 0;
      int paperCount = 0;
      int otherCount = 0;
      int recyclable = 0;
      int nonRecyclable = 0;

      for (final scan in scans) {
        final type = (scan["material_type"] ?? "other")
            .toString()
            .toLowerCase()
            .trim();

        if (_isRecyclable(scan["recyclable"])) {
          recyclable++;
        } else {
          nonRecyclable++;
        }

        if (type.contains("plastic")) {
          plasticCount++;
        } else if (type.contains("glass")) {
          glassCount++;
        } else if (type.contains("metal") || type.contains("can")) {
          metalCount++;
        } else if (type.contains("organic")) {
          organicCount++;
        } else if (type.contains("paper") || type.contains("carton")) {
          paperCount++;
        } else {
          otherCount++;
        }
      }

      if (!mounted) return;

      setState(() {
        scansList = scans;
        totalScans = scans.length;

        plastic = plasticCount;
        glass = glassCount;
        metal = metalCount;
        organic = organicCount;
        paper = paperCount;
        other = otherCount;

        recyclableCount = recyclable;
        nonRecyclableCount = nonRecyclable;

        isLoading = false;
      });

      _animationController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        errorMessage = "Error loading statistics";
      });
    }
  }

  double get recyclabilityRate {
    if (totalScans == 0) return 0;
    return (recyclableCount / totalScans) * 100;
  }

  double get nonRecyclabilityRate {
    if (totalScans == 0) return 0;
    return (nonRecyclableCount / totalScans) * 100;
  }

  int get materialDiversity {
    int count = 0;

    if (plastic > 0) count++;
    if (glass > 0) count++;
    if (metal > 0) count++;
    if (organic > 0) count++;
    if (paper > 0) count++;
    if (other > 0) count++;

    return count;
  }

  int get highestCategoryValue {
    final values = [plastic, glass, metal, organic, paper, other];
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    return maxValue == 0 ? 1 : maxValue;
  }

  List<MapEntry<String, int>> get materialRanking {
    final map = {
      "Plastic": plastic,
      "Glass": glass,
      "Metal": metal,
      "Organic": organic,
      "Paper": paper,
      "Other": other,
    };

    final list = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return list;
  }

  String get topCategory {
    final sorted = materialRanking;

    if (sorted.first.value == 0) return "No data yet";
    return sorted.first.key;
  }

  int get activeDays {
    final dates = scansList
        .map((scan) => _scanDate(scan["created_at"]))
        .whereType<DateTime>()
        .toList();

    if (dates.isEmpty) return 0;

    dates.sort();

    final first = DateTime(dates.first.year, dates.first.month, dates.first.day);
    final last = DateTime(dates.last.year, dates.last.month, dates.last.day);

    return last.difference(first).inDays + 1;
  }

  double get averageScansPerDay {
    if (activeDays == 0) return 0;
    return totalScans / activeDays;
  }

  String get mostActiveDay {
    final Map<String, int> days = {
      "Monday": 0,
      "Tuesday": 0,
      "Wednesday": 0,
      "Thursday": 0,
      "Friday": 0,
      "Saturday": 0,
      "Sunday": 0,
    };

    for (final scan in scansList) {
      final date = _scanDate(scan["created_at"]);
      if (date == null) continue;

      final dayName = _weekdayName(date.weekday);
      days[dayName] = (days[dayName] ?? 0) + 1;
    }

    final sorted = days.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.first.value == 0) return "No data";
    return sorted.first.key;
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return "Monday";
      case 2:
        return "Tuesday";
      case 3:
        return "Wednesday";
      case 4:
        return "Thursday";
      case 5:
        return "Friday";
      case 6:
        return "Saturday";
      case 7:
        return "Sunday";
      default:
        return "Unknown";
    }
  }

  String get recyclerLevel {
    if (totalScans >= 100) return "Recycling Expert";
    if (totalScans >= 50) return "Green Champion";
    if (totalScans >= 20) return "Eco Explorer";
    return "Beginner Recycler";
  }

  String get analyticsInsight {
    if (totalScans == 0) {
      return "Start scanning items to generate personalized recycling statistics.";
    }

    return "$topCategory is your most scanned material. "
        "Your recyclability rate is ${recyclabilityRate.toStringAsFixed(0)}%. "
        "You scanned $materialDiversity different material types with an average of ${averageScansPerDay.toStringAsFixed(1)} scans per day.";
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
      case "paper":
        return Colors.teal;
      case "other":
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData getCategoryIcon(String label) {
    switch (label.toLowerCase()) {
      case "plastic":
        return Icons.local_drink_outlined;
      case "glass":
        return Icons.wine_bar_outlined;
      case "metal":
        return Icons.inventory_2_outlined;
      case "organic":
        return Icons.grass_outlined;
      case "paper":
        return Icons.description_outlined;
      case "other":
        return Icons.category_outlined;
      default:
        return Icons.recycling;
    }
  }

  List<PieChartSectionData> buildPieSections() {
    final total = plastic + glass + metal + organic + paper + other;

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

    return materialRanking.map((entry) {
      if (entry.value == 0) {
        return PieChartSectionData(
          value: 0,
          title: "",
          radius: 0,
          color: getCategoryColor(entry.key),
        );
      }

      final percentage = ((entry.value / total) * 100).toStringAsFixed(0);

      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: "$percentage%",
        radius: 58,
        color: getCategoryColor(entry.key),
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
    }).toList();
  }

  List<PieChartSectionData> buildRecyclabilitySections() {
    final total = recyclableCount + nonRecyclableCount;

    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          title: "No Data",
          radius: 50,
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
        value: recyclableCount.toDouble(),
        title: "${recyclabilityRate.toStringAsFixed(0)}%",
        radius: 50,
        color: Colors.green,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      PieChartSectionData(
        value: nonRecyclableCount.toDouble(),
        title: "${nonRecyclabilityRate.toStringAsFixed(0)}%",
        radius: 50,
        color: Colors.redAccent,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
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
              ? _errorView()
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
                              icon: Icons.document_scanner_outlined,
                              color: Colors.green,
                            ),
                            _buildSummaryCard(
                              title: "Recyclability Rate",
                              value: "${recyclabilityRate.toStringAsFixed(0)}%",
                              icon: Icons.check_circle_outline,
                              color: Colors.teal,
                            ),
                            _buildSummaryCard(
                              title: "Top Material",
                              value: topCategory,
                              icon: Icons.emoji_events_outlined,
                              color: Colors.orange,
                            ),
                            _buildSummaryCard(
                              title: "Material Diversity",
                              value: "$materialDiversity Types",
                              icon: Icons.category_outlined,
                              color: Colors.purple,
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        _buildSectionTitle("Material Distribution"),
                        const SizedBox(height: 12),
                        _buildMaterialDistributionCard(),
                        const SizedBox(height: 22),
                        _buildSectionTitle("Recyclability Analysis"),
                        const SizedBox(height: 12),
                        _buildRecyclabilityCard(),
                        const SizedBox(height: 22),
                        _buildSectionTitle("Material Ranking"),
                        const SizedBox(height: 12),
                        _buildRankingCard(),
                        const SizedBox(height: 22),
                        _buildSectionTitle("Usage Averages"),
                        const SizedBox(height: 12),
                        _buildAveragesCard(),
                        const SizedBox(height: 22),
                        _buildSectionTitle("Recycler Level"),
                        const SizedBox(height: 12),
                        _buildLevelCard(),
                        const SizedBox(height: 22),
                        _buildSectionTitle("Analytics Insight"),
                        const SizedBox(height: 12),
                        _buildInsightCard(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _errorView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 140),
        Icon(
          Icons.error_outline,
          size: 60,
          color: Colors.red.shade400,
        ),
        const SizedBox(height: 14),
        Text(
          errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: fetchStats,
          child: const Text("Retry"),
        ),
      ],
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
            "Recycling Analytics",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Detailed statistics based on your scan history, percentages, averages, and material performance.",
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
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteCard({required Widget child}) {
    return Container(
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
      child: child,
    );
  }

  Widget _buildMaterialDistributionCard() {
    return _buildWhiteCard(
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
          ...materialRanking.map(
            (entry) => _buildProgressTile(entry.key, entry.value),
          ),
        ],
      ),
    );
  }

  Widget _buildRecyclabilityCard() {
    return _buildWhiteCard(
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 48,
                sectionsSpace: 3,
                sections: buildRecyclabilitySections(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildRateRow(
            label: "Recyclable Items",
            value: recyclableCount,
            percentage: recyclabilityRate,
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _buildRateRow(
            label: "Non-Recyclable Items",
            value: nonRecyclableCount,
            percentage: nonRecyclabilityRate,
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildRateRow({
    required String label,
    required int value,
    required double percentage,
    required Color color,
  }) {
    final progress = totalScans == 0 ? 0.0 : percentage / 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              "$value items • ${percentage.toStringAsFixed(0)}%",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.grey.shade300,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRankingCard() {
    return _buildWhiteCard(
      child: Column(
        children: materialRanking.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildRankingRow(index, item.key, item.value),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRankingRow(int index, String label, int value) {
    final color = getCategoryColor(label);
    final percentage = totalScans == 0 ? 0 : (value / totalScans) * 100;

    String rank;
    if (index == 0) {
      rank = "🥇";
    } else if (index == 1) {
      rank = "🥈";
    } else if (index == 2) {
      rank = "🥉";
    } else {
      rank = "${index + 1}";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              rank,
              style: const TextStyle(fontSize: 18),
            ),
          ),
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
            "$value • ${percentage.toStringAsFixed(0)}%",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAveragesCard() {
    return _buildWhiteCard(
      child: Column(
        children: [
          _buildAverageRow(
            icon: Icons.calendar_today_outlined,
            title: "Active Days",
            value: "$activeDays days",
            color: Colors.blue,
          ),
          const Divider(height: 26),
          _buildAverageRow(
            icon: Icons.timeline_outlined,
            title: "Average Scans / Day",
            value: averageScansPerDay.toStringAsFixed(1),
            color: Colors.orange,
          ),
          const Divider(height: 26),
          _buildAverageRow(
            icon: Icons.event_available_outlined,
            title: "Most Active Day",
            value: mostActiveDay,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildAverageRow({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildLevelCard() {
    double progress;

    if (totalScans >= 100) {
      progress = 1;
    } else {
      progress = totalScans / 100;
    }

    return _buildWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.workspace_premium, color: Colors.green),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recyclerLevel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "$totalScans scans completed",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade300,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Next milestone: 100 scans",
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    return Container(
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
      child: Row(
        children: [
          const Icon(Icons.auto_graph, color: Colors.white, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              analyticsInsight,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTile(String label, int value) {
    final progress = value / highestCategoryValue;
    final color = getCategoryColor(label);
    final percentage = totalScans == 0 ? 0 : (value / totalScans) * 100;

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
                "$value • ${percentage.toStringAsFixed(0)}%",
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
}