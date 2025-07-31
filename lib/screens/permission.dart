import 'dart:async';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';

import '../auth/navigation_helper.dart';
import '../dashboard/Dashboard.dart';
import '../auth/login.dart';
import '../lifecycle_handler.dart';
import '../widgets/flying_birds.dart';
import '../widgets/ripple_effect.dart';


class LocationPermiter extends StatefulWidget {
  const LocationPermiter({super.key});


  @override
  _LocationPermiterState createState() => _LocationPermiterState();
}


class _LocationPermiterState extends State<LocationPermiter> with WidgetsBindingObserver {

  bool isLoggedIn = false;
  bool locationReady = false;
  bool showLocationSettingsButton = true; // Always true here since this page means location OFF

  final AppLifecycleHandler _lifecycleHandler = AppLifecycleHandler();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addObserver(_lifecycleHandler);
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, re-check location permission/status
      _checkLocationAndProceed();
    }
  }

  Future<void> _checkLocationAndProceed() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      setState(() {
        showLocationSettingsButton = true;
        locationReady = false;
      });
      return; // Stay on this screen
    }

    // Location enabled, check login status & navigate accordingly
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    String? type = prefs.getString('userType');

    setState(() {
      isLoggedIn = userId != null;
      locationReady = true;
      showLocationSettingsButton = false;
    });

    if (isLoggedIn && type != null) {
      await navigateBasedOnUserType(context, type);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!locationReady) {
      return Scaffold(
        body: RefreshIndicator(
          onRefresh: _checkLocationAndProceed,
          child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // allows pull even if content fits screen
            child: SizedBox(
               height: MediaQuery.of(context).size.height,
              child: Stack(
                children: [
                  // Your gradient background, birds, ripple effect etc.
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFECEFF1), // Lighter top
                            Color(0xFF263238), // Darker bottom
                          ],
                        ),
                      ),
                    ),
                  ),
                  const FlyingBirds(topOffset: 60),
                  const Center(child: RippleEffect()),

                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 60),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 150,
                            child: Lottie.asset(
                              'assets/device_location.json',
                              repeat: true,
                              animate: true,
                            ),
                          ),
                          const SizedBox(height: 24),

                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: const TextStyle(fontFamily: 'Roboto'),
                              children: [
                                const TextSpan(
                                  text: 'This app requires\n',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Location Permission',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade200,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white24, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.location_off, color: Colors.white70),
                                const SizedBox(width: 8),
                                const Text(
                                  'Device Location Off',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () async {
                                    bool opened = await Geolocator.openLocationSettings();
                                    if (!opened && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: const Text('Could not open location settings.'),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Enable'),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Pull down to refresh after enabling location',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Location ready: this page should never stay here, but just in case
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: isLoggedIn ? const Dashboard() : LoginPage(),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleHandler);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

