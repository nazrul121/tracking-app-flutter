import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../dashboard/Dashboard.dart';
import '../services/location_updater.dart';
import '../widgets/flying_birds.dart';
import '../widgets/morning_pattern.dart';
import '../widgets/ripple_effect.dart';
import 'navigation_helper.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _StylishLoginPageState();
}

class _StylishLoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String username = '';
  String password = '';
  bool _isLoading = false;

  final List<Map<String, dynamic>> users = [
    {'id':'1','username': 'customer1', 'password': '123456', 'status': 1, 'type':'customer'},
    {'id':'2','username': 'customer2', 'password': '123456', 'status': 0, 'type':'customer'},
    {'id':'3','username': 'customer3', 'password': '123456', 'status': 1, 'type':'customer'},
    {'id':'4','username': 'provider1', 'password': '123456', 'status': 1, 'type':'provider'},
    {'id':'4','username': 'provider2', 'password': '123456', 'status': 1, 'type':'provider'},
    {'id':'5','username': 'admin', 'password': '123456', 'status': 1, 'type':'admin'},
  ];

  Future<void> _tryLogin() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    _formKey.currentState?.save();
    setState(() => _isLoading = true);

    try {
      // Simulate delay
      await Future.delayed(const Duration(seconds: 1));

      Map<String, dynamic>? user;
      try {
        user = users.firstWhere(
              (u) => u['username'] == username && u['password'] == password,
        );

        await _saveUserToFirestore(user, context);

      } catch ($e) {
        user = null;
        _showMessage($e.toString(), 'error');
      }


    } catch (e) {
      _showMessage('Login failed: $e', 'error');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUserToFirestore(Map<String, dynamic> user, BuildContext context) async {
    print('Start sending data to Firebase...');
    try {
      GeoPoint location = await _getCurrentLocation();
      print("Location: $location");

      final String userId = user['id'].toString();  // Ensure doc ID is a string

      await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .set({
        'location': location,
        'timeStamp': FieldValue.serverTimestamp(),  // Stored as actual timestamp
      });

      // Start background location tracking if needed
      final locationUpdater = LocationUploader(userId);
      locationUpdater.startTracking();

      // Save to SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', userId);
      await prefs.setString('username', user['username']);
      await prefs.setInt('status', user['status']);
      await prefs.setString('userType', user['type']);

      _showMessage('Login successful 🎉', 'success');

      await navigateBasedOnUserType(context, user['type']);

    } catch (e) {
      print("Error saving user data: $e");
      _showMessage('Failed to save data. $e', 'error');
    }
  }

  Future<GeoPoint> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return GeoPoint(position.latitude, position.longitude);
  }


  void _showMessage(String msg, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: type == 'success' ? Colors.green.withAlpha(128) : Colors.red.withAlpha(128), // semi-transparent red
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: type == 'success' ? Colors.green : Colors.red,  // border color
              width: 2,             // border thickness
            ),
          ),
          content: Text(
            msg,
            style: TextStyle(color: type == 'success' ? Colors.green : Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.withValues(alpha: 0.3),
      body:Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF3091D1), // Lighter top
                    Color(0xFF263238), // Darker bottom
                  ],
                ),
              ),
            ),
          ),
          // 🐦 Birds flying a bit below top
          FlyingBirds(topOffset: 60),

          // 🌤️ Sun with intense glow + shadow
          MorningPattern(),

          // 📍 Ripple around icon
          Center(child: RippleEffect()),

          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [

                    Icon(Icons.lock_outline, size: 80, color: Colors.blueAccent),
                    SizedBox(height: 20),
                    Text('Please login to continue', style: TextStyle(color: Colors.grey.shade200, fontSize: 18)),
                    SizedBox(height: 32),

                    // Username field
                    TextFormField(
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                        prefixIcon: Icon(Icons.person, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white10,
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 25),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueGrey.shade200, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent, width: 2.5),
                          borderRadius: BorderRadius.circular(12),
                        ),

                      ),
                      onSaved: (value) => username = value?.trim() ?? '',
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your username';
                        return null;
                      },
                    ),
                    SizedBox(height: 20),

                    // Password field
                    TextFormField(
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
                        prefixIcon: Icon(Icons.lock, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white10,
                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 25),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueGrey.shade200, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent, width: 2.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      obscureText: true,
                      onSaved: (value) => password = value ?? '',
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your password';
                        if (value.length < 3) return 'Minimum 3 characters';
                        return null;
                      },
                    ),
                    SizedBox(height: 30),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _tryLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent.withValues(alpha: 0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white54,
                                backgroundColor: Colors.blueGrey,
                                strokeWidth: 2.5,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text("Logging in...", style: TextStyle(fontSize: 16, color: Colors.white54)),
                          ],
                        ):
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_open, color: Colors.white,), SizedBox(width: 5,),
                            Text('Login ', style: TextStyle(fontSize: 18, color: Colors.white.withValues(alpha: 0.8)))
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Footer text
                    TextButton(
                      onPressed: () {},
                      child: Text("Don't have an account? Sign up", style: TextStyle(color: Colors.blueGrey)),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      )
    );
  }
}
