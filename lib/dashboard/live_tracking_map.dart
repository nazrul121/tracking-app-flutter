import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_updater.dart';

class LiveTrackingMap extends StatefulWidget {
  final String userId;

  const LiveTrackingMap({Key? key, required this.userId}) : super(key: key);

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Marker? _userMarker;
  LatLng? _lastPosition;
  String _lastUpdated = '';


  late LocationUploader _locationUploader;
  Stream<DocumentSnapshot> get userLocationStream {
    return FirebaseFirestore.instance
        .collection('user')
        .doc(widget.userId)
        .snapshots();
  }

  double _currentZoom = 16.0;
  void _updateMarkerAndCamera(LatLng position) async {
    if (_mapController != null) {
      _currentZoom = await _mapController!.getZoomLevel();
    }

    setState(() {
      _userMarker = Marker(
        markerId: MarkerId(widget.userId),
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

  @override
  void initState() {
    super.initState();
    _locationUploader = LocationUploader(widget.userId);
    _locationUploader.startTracking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tracking ${widget.userId}')),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
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
                  onMapCreated: (controller) => _mapController = controller,
                  myLocationButtonEnabled: false,
                ),
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Last updated: $_lastUpdated',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
