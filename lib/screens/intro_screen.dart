import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'onboarding_slider.dart';
import 'dashboard/dashboard_page.dart';


class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _scale;
  Animation<double>? _fade;

  @override
  void initState() {
    super.initState();

    // ✅ CHECK SAVED LOGIN
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
      });
      return;
    }

    // 🔁 Intro animation (only if not saved)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scale = Tween<double>(begin: 0.85, end: 1.1).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
    );

    _fade = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _goToBoarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BriefOnboardingScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF1F8E9),
              Color(0xFFAED581),
              Color(0xFF7CB342),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller ?? kAlwaysCompleteAnimation,
                builder: (_, child) {
                  return Transform.scale(
                    scale: _scale?.value ?? 1.0,
                    child: Opacity(
                      opacity: _fade?.value ?? 1.0,
                      child: child,
                    ),
                  );
                },
                child: const Icon(
                  Icons.recycling,
                  size: 140,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Smart Pre-Recycling',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Recycle smarter. Reduce waste. Make a greener future!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 70),
              ElevatedButton(
                onPressed: _goToBoarding,
                child: const Text("Get Started"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
