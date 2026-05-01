import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart';
import '../intro_screen.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notifications = true;
  bool autoLocation = true;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: const Color(0xFF7CB342),
      ),
      backgroundColor: const Color(0xFFF1F8E9),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, themeMode, _) {
          final bool darkMode = themeMode == ThemeMode.dark;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.green,
                      child: Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.email?.split("@")[0] ?? "User",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? "No email",
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle("Preferences"),
              _settingsCard(
                children: [
                  SwitchListTile(
                    value: darkMode,
                    onChanged: (value) {
                      themeNotifier.value =
                          value ? ThemeMode.dark : ThemeMode.light;
                    },
                    title: const Text("Dark Mode"),
                    subtitle: const Text("Switch app appearance"),
                    secondary: const Icon(Icons.dark_mode_outlined),
                    activeThumbColor: Colors.green,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: notifications,
                    onChanged: (value) {
                      setState(() => notifications = value);
                    },
                    title: const Text("Notifications"),
                    subtitle: const Text("Receive recycling reminders"),
                    secondary: const Icon(Icons.notifications_outlined),
                    activeThumbColor: Colors.green,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: autoLocation,
                    onChanged: (value) {
                      setState(() => autoLocation = value);
                    },
                    title: const Text("Auto Location"),
                    subtitle: const Text("Find nearby recycling centers"),
                    secondary: const Icon(Icons.location_on_outlined),
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle("Information"),
              _settingsCard(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text("About App"),
                    subtitle: const Text("Learn more about this project"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showAboutDialog(
                        context: context,
                        applicationName: "Smart Pre-Recycling",
                        applicationVersion: "1.0.0",
                        children: const [
                          Text(
                            "Smart Pre-Recycling helps users classify waste, track recycling impact, and find nearby recycling centers.",
                          ),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text("Privacy Policy"),
                    subtitle: const Text("How your data is handled"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showInfoDialog(
                        title: "Privacy Policy",
                        content:
                            "Your account information is used only داخل التطبيق لتحسين تجربة الاستخدام وعرض بيانات إعادة التدوير الخاصة بك.",
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text("Terms & Conditions"),
                    subtitle: const Text("Application terms of use"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showInfoDialog(
                        title: "Terms & Conditions",
                        content:
                            "This app is a graduation project prototype for educational purposes. Users should use the recycling recommendations as guidance.",
                      );
                    },
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.system_update_alt),
                    title: Text("App Version"),
                    subtitle: Text("Smart Pre-Recycling"),
                    trailing: Text("1.0.0"),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle("Support"),
              _settingsCard(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text("Help Center"),
                    subtitle: const Text("Common app guidance"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showInfoDialog(
                        title: "Help Center",
                        content:
                            "Use Scan to add items, History to review previous scans, Dashboard to track your recycling impact, and Map to find recycling centers.",
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.shield_outlined),
                    title: const Text("Account Security"),
                    subtitle: const Text("Authentication and protection info"),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      _showInfoDialog(
                        title: "Account Security",
                        content:
                            "Your account is secured using Firebase Authentication. Password management is handled through Firebase login.",
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text("Logout"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () async {
                    final confirm = await _showLogoutDialog();
                    if (confirm == true) {
                      await FirebaseAuth.instance.signOut();

                      if (!context.mounted) return;

                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IntroScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _settingsCard({required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: children),
    );
  }

  Future<void> _showInfoDialog({
    required String title,
    required String content,
  }) async {
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showLogoutDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}