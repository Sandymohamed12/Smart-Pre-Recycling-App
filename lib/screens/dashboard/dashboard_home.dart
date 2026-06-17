import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/user_session.dart';
import '../ai/scan_page.dart';
import '../instructions/how_to_recycle_page.dart';
import '../map/map_page.dart';
import 'dashboard_stats.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  bool isLoading = true;
  String? errorMessage;

  int totalScans = 0;
  int recyclableCount = 0;
  int nonRecyclableCount = 0;

  int plasticCount = 0;
  int glassCount = 0;
  int metalCount = 0;
  int organicCount = 0;
  int paperCount = 0;
  int otherCount = 0;

  List<dynamic> scans = [];
  List<dynamic> recentScans = [];

  String get baseUrl =>
      kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";

  @override
  void initState() {
    super.initState();
    loadDashboardData();
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

      final response = await http.get(
        Uri.parse("$baseUrl/scans/user/${UserSession.backendUserId}"),
      );

      if (response.statusCode != 200) {
        setState(() {
          isLoading = false;
          errorMessage = "Failed to load dashboard data";
        });
        return;
      }

      final List data = jsonDecode(response.body);

      int plastic = 0;
      int glass = 0;
      int metal = 0;
      int organic = 0;
      int paper = 0;
      int other = 0;
      int recyclable = 0;
      int nonRecyclable = 0;

      for (final scan in data) {
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
          plastic++;
        } else if (type.contains("glass")) {
          glass++;
        } else if (type.contains("metal") || type.contains("can")) {
          metal++;
        } else if (type.contains("organic")) {
          organic++;
        } else if (type.contains("paper") || type.contains("carton")) {
          paper++;
        } else {
          other++;
        }
      }

      setState(() {
        scans = data;
        totalScans = data.length;
        recyclableCount = recyclable;
        nonRecyclableCount = nonRecyclable;

        plasticCount = plastic;
        glassCount = glass;
        metalCount = metal;
        organicCount = organic;
        paperCount = paper;
        otherCount = other;

        recentScans = data.reversed.take(5).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error loading dashboard";
      });
    }
  }

  double get recyclabilityRate {
    if (totalScans == 0) return 0;
    return (recyclableCount / totalScans) * 100;
  }

  int get materialDiversity {
    int count = 0;
    if (plasticCount > 0) count++;
    if (glassCount > 0) count++;
    if (metalCount > 0) count++;
    if (organicCount > 0) count++;
    if (paperCount > 0) count++;
    if (otherCount > 0) count++;
    return count;
  }

  String get topMaterial {
    final map = {
      "Plastic": plasticCount,
      "Glass": glassCount,
      "Metal": metalCount,
      "Organic": organicCount,
      "Paper": paperCount,
      "Other": otherCount,
    };

    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.first.value == 0) return "No data";
    return sorted.first.key;
  }

  int get weeklyScans {
    final now = DateTime.now();

    return scans.where((scan) {
      final date = _scanDate(scan["created_at"]);
      if (date == null) return false;
      return now.difference(date).inDays <= 7;
    }).length;
  }

  int get currentStreak {
    final dates = scans
        .map((scan) => _scanDate(scan["created_at"]))
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList();

    if (dates.isEmpty) return 0;

    dates.sort((a, b) => b.compareTo(a));

    int streak = 1;
    DateTime current = dates.first;

    for (int i = 1; i < dates.length; i++) {
      final expected = current.subtract(const Duration(days: 1));
      if (dates[i] == expected) {
        streak++;
        current = dates[i];
      } else {
        break;
      }
    }

    return streak;
  }

  int get bestStreak {
    final dates = scans
        .map((scan) => _scanDate(scan["created_at"]))
        .whereType<DateTime>()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet()
        .toList();

    if (dates.isEmpty) return 0;

    dates.sort();

    int best = 1;
    int current = 1;

    for (int i = 1; i < dates.length; i++) {
      if (dates[i].difference(dates[i - 1]).inDays == 1) {
        current++;
        best = current > best ? current : best;
      } else {
        current = 1;
      }
    }

    return best;
  }

  String get recyclerRank {
    if (totalScans >= 100) return "Recycling Expert";
    if (totalScans >= 50) return "Green Champion";
    if (totalScans >= 20) return "Eco Explorer";
    return "Beginner Recycler";
  }

  int get nextRankTarget {
    if (totalScans < 20) return 20;
    if (totalScans < 50) return 50;
    if (totalScans < 100) return 100;
    return totalScans;
  }

  String get nextRankName {
    if (totalScans < 20) return "Eco Explorer";
    if (totalScans < 50) return "Green Champion";
    if (totalScans < 100) return "Recycling Expert";
    return "Max Level";
  }

  double get rankProgress {
    if (nextRankTarget == 0) return 0;
    if (totalScans >= 100) return 1;
    return (totalScans / nextRankTarget).clamp(0, 1).toDouble();
  }

  String get smartRecommendation {
    if (totalScans == 0) {
      return "Start scanning items to unlock personalized recycling recommendations.";
    }

    if (topMaterial == "Plastic") {
      return "Most of your scans are plastic. Try scanning more glass and metal items to improve material diversity.";
    }

    if (topMaterial == "Glass") {
      return "Glass appears often in your scans. Make sure bottles are rinsed and caps are separated.";
    }

    if (topMaterial == "Metal") {
      return "Metal is your top material. Empty cans before recycling for better preparation.";
    }

    if (topMaterial == "Paper") {
      return "Paper is common in your scans. Keep it dry and clean before recycling.";
    }

    if (recyclabilityRate >= 75) {
      return "Great work! Your recyclability rate is high. Keep separating recyclable items before disposal.";
    }

    return "Your scan history has mixed results. Try taking clearer photos and checking item labels.";
  }

  String get tipOfTheDay {
    final tips = [
      "Remove bottle caps before recycling plastic bottles.",
      "Keep paper dry because wet paper is harder to recycle.",
      "Rinse glass containers before placing them in recycling bins.",
      "Empty metal cans before recycling them.",
      "Separate organic waste for composting when possible.",
    ];

    return tips[DateTime.now().day % tips.length];
  }

  String get didYouKnow {
    final facts = [
      "Glass can be recycled many times without losing quality.",
      "Aluminum cans are one of the most recyclable packaging materials.",
      "Clean paper is easier to recycle than contaminated paper.",
      "Sorting waste before disposal improves recycling efficiency.",
      "Plastic recycling depends on the plastic type and local recycling rules.",
    ];

    return facts[DateTime.now().weekday % facts.length];
  }

  String _formatMaterial(String? value) {
    if (value == null || value.trim().isEmpty) return "Unknown";

    return value
        .replaceAll("_", " ")
        .split(" ")
        .map(
          (word) =>
              word.isEmpty ? "" : word[0].toUpperCase() + word.substring(1),
        )
        .join(" ");
  }

  String _formatRelativeDate(dynamic value) {
    final date = _scanDate(value);
    if (date == null) return "Unknown date";

    final now = DateTime.now();
    final cleanNow = DateTime(now.year, now.month, now.day);
    final cleanDate = DateTime(date.year, date.month, date.day);

    final diff = cleanNow.difference(cleanDate).inDays;

    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";
    return "$diff days ago";
  }

  IconData _materialIcon(String material) {
    final value = material.toLowerCase();

    if (value.contains("plastic")) return Icons.local_drink_outlined;
    if (value.contains("glass")) return Icons.wine_bar_outlined;
    if (value.contains("metal") || value.contains("can")) {
      return Icons.inventory_2_outlined;
    }
    if (value.contains("paper") || value.contains("carton")) {
      return Icons.description_outlined;
    }
    if (value.contains("organic")) return Icons.grass_outlined;

    return Icons.recycling;
  }

  Color _materialColor(String material) {
    final value = material.toLowerCase();

    if (value.contains("plastic")) return Colors.blue;
    if (value.contains("glass")) return Colors.green;
    if (value.contains("metal") || value.contains("can")) return Colors.orange;
    if (value.contains("paper") || value.contains("carton")) return Colors.teal;
    if (value.contains("organic")) return Colors.brown;

    return Colors.purple;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.email?.split("@").first ?? "User";

    return RefreshIndicator(
      onRefresh: loadDashboardData,
      child: isLoading
          ? _loadingView()
          : errorMessage != null
              ? _errorView()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _heroHeader(name),
                    const SizedBox(height: 22),
                    _sectionTitle("Quick Actions"),
                    const SizedBox(height: 12),
                    _quickActions(),
                    const SizedBox(height: 22),
                    _weeklyGoalCard(),
                    const SizedBox(height: 16),
                    _streakCard(),
                    const SizedBox(height: 22),
                    _sectionTitle("Achievements"),
                    const SizedBox(height: 12),
                    _achievementsSection(),
                    const SizedBox(height: 22),
                    _sectionTitle("Recent Activity"),
                    const SizedBox(height: 12),
                    _activityTimeline(),
                    const SizedBox(height: 22),
                    _smartRecommendationCard(),
                    const SizedBox(height: 16),
                    _tipCard(),
                    const SizedBox(height: 16),
                    _rankCard(),
                    const SizedBox(height: 16),
                    _didYouKnowCard(),
                    const SizedBox(height: 16),
                  ],
                ),
    );
  }

  Widget _loadingView() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _skeletonBox(210),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _skeletonBox(95)),
            const SizedBox(width: 12),
            Expanded(child: _skeletonBox(95)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _skeletonBox(95)),
            const SizedBox(width: 12),
            Expanded(child: _skeletonBox(95)),
          ],
        ),
        const SizedBox(height: 18),
        _skeletonBox(150),
        const SizedBox(height: 18),
        _skeletonBox(180),
      ],
    );
  }

  Widget _skeletonBox(double height) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(24),
      ),
    );
  }

  Widget _errorView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 120),
        Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
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
    );
  }

  Widget _heroHeader(String name) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            Colors.green.shade800,
            Colors.green.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -8,
            child: Icon(
              Icons.recycling,
              size: 120,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(name),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "$recyclerRank 🌱",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _heroMetric("$totalScans", "Scans"),
                  _heroMetric(
                    "${recyclabilityRate.toStringAsFixed(0)}%",
                    "Recyclable",
                  ),
                  _heroMetric("$materialDiversity", "Materials"),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _greeting(String name) {
    final hour = DateTime.now().hour;

    if (hour < 12) return "Good Morning, $name 👋";
    if (hour < 18) return "Good Afternoon, $name 👋";
    return "Good Evening, $name 👋";
  }

  Widget _heroMetric(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _quickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: [
        _quickActionCard(
          title: "Scan Item",
          icon: Icons.camera_alt_outlined,
          color: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScanPage()),
            );
          },
        ),
        _quickActionCard(
          title: "Centers",
          icon: Icons.map_outlined,
          color: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapPage()),
            );
          },
        ),
        _quickActionCard(
          title: "Guide",
          icon: Icons.menu_book_outlined,
          color: Colors.orange,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HowToRecyclePage()),
            );
          },
        ),
        _quickActionCard(
          title: "Statistics",
          icon: Icons.analytics_outlined,
          color: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DashboardStats()),
            );
          },
        ),
      ],
    );
  }

  Widget _quickActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            CircleAvatar(
              radius: 23,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _weeklyGoalCard() {
    const goal = 10;
    final progress = (weeklyScans / goal).clamp(0, 1).toDouble();
    final left = goal - weeklyScans;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flag_outlined, color: Colors.green),
              SizedBox(width: 8),
              Text(
                "Weekly Challenge",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "$weeklyScans / $goal scans completed",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade300,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            left <= 0
                ? "Amazing! You completed this week's goal."
                : "$left scans left to complete your weekly goal.",
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _streakCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            height: 76,
            width: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.deepOrange.withOpacity(0.12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$currentStreak",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                const Text(
                  "Days",
                  style: TextStyle(fontSize: 12, color: Colors.deepOrange),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "🔥 Scan Streak",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  "Current streak: $currentStreak days",
                  style: const TextStyle(color: Colors.black54),
                ),
                Text(
                  "Best streak: $bestStreak days",
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _achievementsSection() {
    final achievements = [
      _Achievement("First Scan", Icons.looks_one, totalScans >= 1),
      _Achievement("10 Scans", Icons.workspace_premium, totalScans >= 10),
      _Achievement("Plastic Explorer", Icons.local_drink, plasticCount >= 5),
      _Achievement("Glass Expert", Icons.wine_bar, glassCount >= 5),
      _Achievement("Green Champion", Icons.emoji_events, totalScans >= 50),
    ];

    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final item = achievements[index];

          return Container(
            width: 110,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: item.unlocked ? Colors.white : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(22),
              boxShadow: item.unlocked
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.unlocked ? item.icon : Icons.lock_outline,
                  color: item.unlocked ? Colors.green : Colors.grey,
                  size: 30,
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: item.unlocked ? Colors.black87 : Colors.black45,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _activityTimeline() {
    if (recentScans.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            const Text(
              "No scans yet. Start recycling to see your activity here.",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text("Start first scan"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanPage()),
                );
              },
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: List.generate(recentScans.length, (index) {
          final scan = recentScans[index];
          final material = _formatMaterial(scan["material_type"]?.toString());
          final color = _materialColor(material);
          final isLast = index == recentScans.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: color.withOpacity(0.15),
                    child: Icon(_materialIcon(material), color: color, size: 16),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 42,
                      color: Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatRelativeDate(scan["created_at"]),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _smartRecommendationCard() {
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
          const Icon(Icons.psychology_alt_outlined,
              color: Colors.white, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              smartRecommendation,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipCard() {
    return _infoCard(
      icon: Icons.lightbulb_outline,
      title: "Tip of the Day",
      text: tipOfTheDay,
      color: Colors.amber.shade700,
    );
  }

  Widget _rankCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium_outlined, color: Colors.green),
              SizedBox(width: 8),
              Text(
                "Recycler Rank",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recyclerRank,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            totalScans >= 100
                ? "You reached the highest level."
                : "$totalScans / $nextRankTarget scans • Next: $nextRankName",
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: rankProgress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade300,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _didYouKnowCard() {
    return _infoCard(
      icon: Icons.eco_outlined,
      title: "Did You Know?",
      text: didYouKnow,
      color: Colors.green,
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: const TextStyle(color: Colors.black54, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.055),
          blurRadius: 14,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

class _Achievement {
  final String title;
  final IconData icon;
  final bool unlocked;

  const _Achievement(this.title, this.icon, this.unlocked);
}