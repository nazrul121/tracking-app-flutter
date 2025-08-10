import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gmap_tracking/dashboard/customer/widgets/request_service_popup.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';

import '../../../services/location_updater.dart';


class CustomerLocation extends StatefulWidget {

  CustomerLocation({super.key});

  @override
  State<CustomerLocation> createState() => _MyLocationState();
}

class _MyLocationState extends State<CustomerLocation> {
  LatLng? currentLocation;
  String userId = '';
  bool isLoading = true;

  GoogleMapController? _mapController;
  Marker? _userMarker;
  LatLng? _lastPosition;
  String _lastUpdated = '';

  StreamSubscription<Position>? _positionStream;


  MapType _currentMapType = MapType.normal;
  bool isTrafficEnabled = false;

  // Map for display names
  final Map<MapType, String> mapTypeNames = {
    MapType.normal: 'Normal',
    MapType.satellite: 'Satellite',
    MapType.terrain: 'Terrain',
    MapType.hybrid: 'Hybrid',
    MapType.none: 'None',
  };

  late LocationUploader _locationUploader;
  Stream<DocumentSnapshot> get userLocationStream {
    return FirebaseFirestore.instance
        .collection('user')
        .doc(userId)
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();

    _locationUploader = LocationUploader(userId);
    _locationUploader.startTracking();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('user_id')!;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        final GeoPoint geoPoint = data['location'];

        setState(() {
          currentLocation = LatLng(geoPoint.latitude, geoPoint.longitude);
          isLoading = false;
        });
      } else {
        _showError('No location found');
      }
    } catch (e) {
      _showError('Error fetching location: $e');
    }
  }


  double _currentZoom = 16.0;
  void _updateMarkerAndCamera(LatLng position) async {
    if (_mapController != null) {
      _currentZoom = await _mapController!.getZoomLevel();
    }

    setState(() {
      _userMarker = Marker(
        markerId: MarkerId(userId),
        position: position,
        infoWindow: InfoWindow(title: 'User Location'),
      );
      _lastPosition = position;
    });

    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: _currentZoom),
        ),
      );
    }
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${twoDigits(dt.month)}-${twoDigits(dt.day)} ${twoDigits(dt.hour)}:${twoDigits(dt.minute)}:${twoDigits(dt.second)}';
  }


  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }



  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.8,
      child: isLoading==false? StreamBuilder<DocumentSnapshot>(
        stream: userLocationStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('No location data found'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final GeoPoint? geoPoint = data['location'];
          final Timestamp? timestamp = data['timeStamp'];

          if (geoPoint == null) return Center(child: Text('Location not available'));

          final LatLng newPosition = LatLng(geoPoint.latitude, geoPoint.longitude);

          if (_lastPosition == null ||
              _lastPosition!.latitude != newPosition.latitude ||
              _lastPosition!.longitude != newPosition.longitude) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateMarkerAndCamera(newPosition);
              setState(() {
                _lastUpdated = _formatTimestamp(timestamp);
              });
            });
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(target: newPosition, zoom: 16),
                markers: _userMarker != null ? {_userMarker!} : {},

                trafficEnabled: isTrafficEnabled,
                mapType: _currentMapType,
                onMapCreated: (controller) => _mapController = controller,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: true,
              ),

              // traffic light
              Positioned(
                top: 40, right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(
                      isTrafficEnabled ? Icons.traffic : Icons.traffic_outlined,
                      color: isTrafficEnabled ? Colors.red: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        isTrafficEnabled = !isTrafficEnabled;
                      });
                    },
                  ),
                ),
              ),
              // service request
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xB20877E6), // Solid dark blue/purple color
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const RequestServicePopup(),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                    label: const Text(
                      'Request a service',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
              ),


              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top:30, left: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        margin: EdgeInsets.only(bottom: 25),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: DropdownButton<MapType>(
                          value: _currentMapType,
                          dropdownColor: Colors.white.withValues(alpha: 0.8),
                          underline: SizedBox(), // Remove default underline
                          style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold),
                          items: mapTypeNames.entries.map((entry) {
                            return DropdownMenuItem<MapType>(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }).toList(),
                          onChanged: (MapType? newType) {
                            if (newType != null) {
                              setState(() {
                                _currentMapType = newType;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            ],
          );
        },
      ):Container(
        color: Colors.blueGrey.withValues(alpha: 0.1),
        height: double.infinity,
        child:Center(
          child: SizedBox(
            height: 25, width: 25,
            child: CircularProgressIndicator(
              color: Colors.blueGrey,backgroundColor: Colors.blue,
            ),
          ),
        )
      )
    );
  }
}
