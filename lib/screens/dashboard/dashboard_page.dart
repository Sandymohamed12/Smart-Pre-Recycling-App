import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../onboarding_main.dart';
import 'dashboard_home.dart';
import 'dashboard_stats.dart';
import 'dashboard_history.dart';
import '../profile/profile_page.dart';
import '../settings/settings_page.dart';
import '../ai/scan_page.dart';
import '../map/map_page.dart';
import '../instructions/how_to_recycle_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _index = 0;

  final List<Widget> pages = const [
    DashboardHome(),
    DashboardStats(),
    DashboardHistory(),
  ];

  final List<String> titles = const [
    "Dashboard",
    "Statistics",
    "History",
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.green,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Recycle Me",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? "",
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    _DrawerItem(
                      title: "Home",
                      icon: Icons.home_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _index = 0);
                      },
                    ),
                    _DrawerItem(
                      title: "Recycle an Item",
                      icon: Icons.camera_alt_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ScanPage()),
                        );
                      },
                    ),
                    _DrawerItem(
                      title: "Where to Recycle",
                      icon: Icons.map_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MapPage()),
                        );
                      },
                    ),
                    _DrawerItem(
                      title: "How to Recycle",
                      icon: Icons.menu_book_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HowToRecyclePage(),
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    _DrawerItem(
                      title: "Profile",
                      icon: Icons.person_outline,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ProfilePage()),
                        );
                      },
                    ),
                    _DrawerItem(
                      title: "Settings",
                      icon: Icons.settings_outlined,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SettingsPage()),
                        );
                      },
                    ),
                    _DrawerItem(
                      title: "About",
                      icon: Icons.info_outline,
                      onTap: () {
                        Navigator.pop(context);
                        showAboutDialog(
                          context: context,
                          applicationName: "Recycle Me",
                          applicationVersion: "1.0.0",
                          children: const [
                            Text(
                              "Recycle Me helps users classify waste, track recycling impact, and find nearby recycling centers.",
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              _DrawerItem(
                title: "Logout",
                icon: Icons.logout,
                isDanger: true,
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (!context.mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const IntroScreen()),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        title: Text(titles[_index]),
        backgroundColor: const Color(0xFF7CB342),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: pages[_index],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        selectedItemColor: Colors.green.shade800,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: "Stats",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: "History",
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDanger;

  const _DrawerItem({
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDanger ? Colors.red : Colors.black87,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? Colors.red : Colors.black87,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }
}