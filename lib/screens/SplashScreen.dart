import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/navigation_helper.dart';
import '../widgets/burning_sun.dart';
import '../widgets/flying_birds.dart';
import '../widgets/ripple_effect.dart';
import 'permission.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  bool loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLocationAndNavigate();
  }

  Future<void> _checkLocationAndNavigate() async {
    // Wait a bit so splash UI shows briefly (optional)
    await Future.delayed(const Duration(seconds: 2));

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled || permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      // Go to LocationPermiter screen to request permission / enable location
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LocationPermiter()),
      );
      return;
    }

    print('redirecting to related page');
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('userType')) {
      String type = prefs.getString('userType')!;
      print(type);
      await navigateBasedOnUserType(context, type);
    }else{
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LocationPermiter()),
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFECEFF1),
                    Color(0xFF263238),
                  ],
                ),
              ),
            ),
          ),

          // 🌤️ Sun with intense glow + shadow
          BurningSun(screenWidth: 400),

          // 🐦 Birds flying a bit below top
          FlyingBirds(topOffset: 60),

          // 📍 Ripple around icon
          Center(child: RippleEffect()),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: Colors.orangeAccent,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'TrackEasy',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Connecting customers & service providers\nvia Google Maps in real time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                // const SizedBox(height: 40),
                // const CircularProgressIndicator(
                //   valueColor: AlwaysStoppedAnimation(Colors.orangeAccent),
                //   strokeWidth: 2.5,
                // )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
