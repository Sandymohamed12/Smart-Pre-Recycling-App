import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../../services/api_service.dart';
import '../../services/user_session.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isLoading = true;
  String? errorMessage;

  String userName = "User";
  String userEmail = "-";

  int totalScans = 0;
  int recyclableCount = 0;
  int nonRecyclableCount = 0;

  int plasticCount = 0;
  int glassCount = 0;
  int metalCount = 0;
  int organicCount = 0;
  int paperCount = 0;
  int otherCount = 0;

  String get baseUrl =>
      kIsWeb ? "http://127.0.0.1:8000" : "http://10.0.2.2:8000";

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  bool _isRecyclable(dynamic value) {
    return value == true ||
        value == 1 ||
        value.toString().toLowerCase() == "true";
  }

  Future<void> loadProfile() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      userEmail = firebaseUser?.email ?? "-";

      if (UserSession.backendUserId == null) {
        setState(() {
          isLoading = false;
          errorMessage = "User session not found";
        });
        return;
      }

      final userData = await ApiService.getUserById(UserSession.backendUserId!);

      final scansResponse = await http.get(
        Uri.parse("$baseUrl/scans/user/${UserSession.backendUserId}"),
      );

      List scans = [];
      if (scansResponse.statusCode == 200) {
        scans = jsonDecode(scansResponse.body);
      }

      int recyclable = 0;
      int nonRecyclable = 0;
      int plastic = 0;
      int glass = 0;
      int metal = 0;
      int organic = 0;
      int paper = 0;
      int other = 0;

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
        userName = (userData["name"]?.toString().trim().isNotEmpty ?? false)
            ? userData["name"].toString()
            : "User";

        userEmail = userData["email"] ?? userEmail;

        totalScans = scans.length;
        recyclableCount = recyclable;
        nonRecyclableCount = nonRecyclable;

        plasticCount = plastic;
        glassCount = glass;
        metalCount = metal;
        organicCount = organic;
        paperCount = paper;
        otherCount = other;

        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Failed to load profile";
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

  String get recyclerRank {
    if (totalScans >= 100) return "Recycling Expert";
    if (totalScans >= 50) return "Green Champion";
    if (totalScans >= 20) return "Eco Explorer";
    return "Beginner Recycler";
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

  double get rankProgress {
    if (totalScans >= 100) return 1;
    if (totalScans >= 50) return totalScans / 100;
    if (totalScans >= 20) return totalScans / 50;
    return totalScans / 20;
  }

  String get nextRank {
    if (totalScans < 20) return "Eco Explorer";
    if (totalScans < 50) return "Green Champion";
    if (totalScans < 100) return "Recycling Expert";
    return "Max Level";
  }

  int get nextRankTarget {
    if (totalScans < 20) return 20;
    if (totalScans < 50) return 50;
    if (totalScans < 100) return 100;
    return totalScans;
  }

  Future<void> _openEditProfile() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          currentName: userName,
          currentEmail: userEmail,
        ),
      ),
    );

    if (updated == true) {
      await loadProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color(0xFF7CB342),
        actions: [
          IconButton(
            onPressed: loadProfile,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: isLoading
          ? _loadingView()
          : errorMessage != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: loadProfile,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _profileHeader(),
                      const SizedBox(height: 18),
                      _rankCard(),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _metricCard(
                              icon: Icons.document_scanner_outlined,
                              title: "Total Scans",
                              value: "$totalScans",
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _metricCard(
                              icon: Icons.check_circle_outline,
                              title: "Recyclability",
                              value: "${recyclabilityRate.toStringAsFixed(0)}%",
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _metricCard(
                              icon: Icons.category_outlined,
                              title: "Materials",
                              value: "$materialDiversity",
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _metricCard(
                              icon: Icons.emoji_events_outlined,
                              title: "Top Material",
                              value: topMaterial,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      _sectionTitle("Achievements"),
                      const SizedBox(height: 12),
                      _achievements(),
                      const SizedBox(height: 22),
                      _sectionTitle("Account Details"),
                      const SizedBox(height: 12),
                      _detailsCard(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label: const Text("Edit Profile"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: _openEditProfile,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
    );
  }

  Widget _loadingView() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  Widget _profileHeader() {
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
            color: Colors.green.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            top: -12,
            child: Icon(
              Icons.eco,
              size: 120,
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          Column(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white.withOpacity(0.18),
                child: const Icon(
                  Icons.person,
                  size: 54,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                userName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                userEmail,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.88),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  "$recyclerRank 🌱",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
                "Recycler Progress",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            recyclerRank,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            totalScans >= 100
                ? "You reached the highest profile level."
                : "$totalScans / $nextRankTarget scans • Next: $nextRank",
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: rankProgress.clamp(0, 1),
              minHeight: 12,
              backgroundColor: Colors.grey.shade300,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
    );
  }

  Widget _achievements() {
    final achievements = [
      _Achievement("First Scan", Icons.looks_one, totalScans >= 1),
      _Achievement("10 Scans", Icons.workspace_premium, totalScans >= 10),
      _Achievement("20 Scans", Icons.emoji_events, totalScans >= 20),
      _Achievement("Plastic Explorer", Icons.local_drink, plasticCount >= 5),
      _Achievement("Glass Expert", Icons.wine_bar, glassCount >= 5),
    ];

    return SizedBox(
      height: 118,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final item = achievements[index];

          return Container(
            width: 108,
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

  Widget _detailsCard() {
    return Container(
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _detailTile(
            icon: Icons.person_outline,
            title: "Name",
            value: userName,
          ),
          const Divider(height: 1),
          _detailTile(
            icon: Icons.email_outlined,
            title: "Email",
            value: userEmail,
          ),
          const Divider(height: 1),
          _detailTile(
            icon: Icons.check_circle_outline,
            title: "Recyclable Items",
            value: "$recyclableCount",
          ),
          const Divider(height: 1),
          _detailTile(
            icon: Icons.cancel_outlined,
            title: "Non-Recyclable Items",
            value: "$nonRecyclableCount",
          ),
        ],
      ),
    );
  }

  Widget _detailTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.green),
      title: Text(title),
      trailing: SizedBox(
        width: 160,
        child: Text(
          value,
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
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