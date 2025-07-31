import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gmap_tracking/dashboard/provider/widgets/menu.dart';
import 'package:gmap_tracking/dashboard/provider/widgets/services.dart';

import '../../utils/location_helper.dart';
import '../my_location.dart';
import 'my_home.dart';

class ProviderHome extends StatefulWidget {
  const ProviderHome({super.key});

  @override
  State<ProviderHome> createState() => _ProviderHomeState();
}


class _ProviderHomeState extends State<ProviderHome> {

  int _selectedIndex = 0;

  final List<String> _titles = ['Home', 'Service', 'Account'];
  final List<IconData> _iconsFilled = [
    Icons.home_filled,
    Icons.build_circle,
    Icons.account_circle,
  ];

  final List<IconData> _iconsOutlined = [
    Icons.home_outlined,
    Icons.build_circle_outlined,
    Icons.account_circle_outlined,
  ];



  // List of pages to show for each tab
  final List<Widget> _pages = [
    ProviderHomeContent(),
    Center(child: ProviderServicePage() ),
    Center(child: Text('Account Page')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Provider Home"),
        actions: [ ProviderMenu() ],
      ),
      body:SafeArea(
        child: SingleChildScrollView(
          child: Stack(
            children: [
              _pages[_selectedIndex],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: List.generate(_titles.length, (index) => _buildNavItem(index)),
        ),
      ),
    );
  }


  Widget _buildNavItem(int index) {
    bool isSelected = index == _selectedIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade100 : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ]
                : [],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? _iconsFilled[index] : _iconsOutlined[index],
                  color: isSelected ? Colors.blue : Colors.grey[600],
                  size: isSelected ? 28 : 24,
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Text(
                    _titles[index],
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }









  Stream<QuerySnapshot>? requestStream;
  String? providerId;
  String? serviceId;
  GeoPoint? providerLocation;

  bool hasShownDialog = false;


  Future<void> _initProviderData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    providerId = uid;

    // Load provider info from Firestore
    final doc = await FirebaseFirestore.instance
        .collection('service_providers')
        .doc(uid)
        .get();

    if (doc.exists) {
      serviceId = doc['service_id'];
      providerLocation = doc['location'];

      // Listen for requests in this service category
      setState(() {
        requestStream = FirebaseFirestore.instance
            .collection('service_request')
            .snapshots();
      });
    }
  }


  bool _isNearby(GeoPoint a, GeoPoint b) {
    const maxDistanceInMeters = 3000;
    final distance = Geolocator.distanceBetween(
      a.latitude, a.longitude,
      b.latitude, b.longitude,
    );
    return distance <= maxDistanceInMeters;
  }


  void _showRequestPopup(Map<String, dynamic> requestData, String docId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("New Service Request"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Service: ${requestData['service_name']}"),
              const SizedBox(height: 10),
              const Text("Do you want to accept this request?"),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Reject"),
              onPressed: () {
                Navigator.of(ctx).pop();
                // Optionally mark request as rejected
              },
            ),
            ElevatedButton(
              child: const Text("Accept"),
              onPressed: () async {
                final providerId = FirebaseAuth.instance.currentUser!.uid;

                await FirebaseFirestore.instance
                    .collection('service_confirmation')
                    .add({
                  'service_id': requestData['service_id'],
                  'provider_id': providerId,
                  'location': providerLocation,
                  'timestamp': Timestamp.now(),
                });

                Navigator.of(ctx).pop();

                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Service Accepted. Contact shared."),
                ));
              },
            ),
          ],
        );
      },
    );
  }


  Future<void> goOnline() async {
    final position = await getCurrentLocation();
    final providerId = FirebaseAuth.instance.currentUser!.uid;
    final serviceId = 'your_service_id'; // You should know this or let provider choose

    await FirebaseFirestore.instance
        .collection('service_provider')
        .doc(serviceId)
        .set({
      'provider_id': providerId,
      'service_id': serviceId,
      'location': GeoPoint(position.latitude, position.longitude),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
