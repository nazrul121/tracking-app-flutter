import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class DistanceCustomerProvider extends StatefulWidget {
  final String customerId;
  final String providerId;
  final bool isCurrentUserCustomer; // 👈 NEW

  const DistanceCustomerProvider({
    super.key,
    required this.customerId,
    required this.providerId,
    required this.isCurrentUserCustomer, // 👈 NEW
  });

  @override
  State<DistanceCustomerProvider> createState() =>
      _DistanceCustomerProviderState();
}


class _DistanceCustomerProviderState extends State<DistanceCustomerProvider> {
  GoogleMapController? mapController;
  Map<MarkerId, Marker> markers = {};
  Polyline? polyline;
  String? distanceText;

  LatLng? customerLatLng;
  LatLng? providerLatLng;

  StreamSubscription<DocumentSnapshot>? customerSub;
  StreamSubscription<DocumentSnapshot>? providerSub;
  StreamSubscription<Position>? positionStream;




  @override
  void initState() {
    super.initState();
    _startLocationListeners();
    _startLiveLocationUpdates();
  }

  void _startLocationListeners() {
    final customerRef =
    FirebaseFirestore.instance.collection('user').doc(widget.customerId);
    final providerRef =
    FirebaseFirestore.instance.collection('user').doc(widget.providerId);

    customerSub = customerRef.snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data != null && data['location'] != null) {
        final geoPoint = data['location'] as GeoPoint;
        customerLatLng = LatLng(geoPoint.latitude, geoPoint.longitude);
        print("Customer updated: $customerLatLng");
        SnackBar(
          content: Text('customer upate: $customerLatLng'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // Perform undo action here
              print('Undo action performed!');
            },
          ),
          duration: Duration(seconds: 2), // Optional: set duration
        );

        if (providerLatLng != null) {  // <- only update if providerLatLng known
          _updateMap();
        }
      }
    });

    providerSub = providerRef.snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data != null && data['location'] != null) {
        final geoPoint = data['location'] as GeoPoint;
        providerLatLng = LatLng(geoPoint.latitude, geoPoint.longitude);
        print("Provider updated: $providerLatLng");
        SnackBar(
          content: Text('provider upate: $customerLatLng'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () {
              // Perform undo action here
              print('Undo action performed!');
            },
          ),
          duration: Duration(seconds: 3), // Optional: set duration
        );

        if (customerLatLng != null) {
          _updateMap();
        }
      }
    });
  }

  Future<void> _updateMap() async {
    if (customerLatLng == null || providerLatLng == null) return;

    final BitmapDescriptor customerIcon = await createCustomMarker('Me');

    final updatedMarkers = <MarkerId, Marker>{
      const MarkerId('customer'): Marker(
        markerId: const MarkerId('customer'),
        position: customerLatLng!,
        infoWindow: const InfoWindow(title: 'Customer'),
        icon: customerIcon,
      ),
      const MarkerId('provider'): Marker(
        markerId: const MarkerId('provider'),
        position: providerLatLng!,
        infoWindow: const InfoWindow(title: 'Provider'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    };

    final poly = Polyline(
      polylineId: const PolylineId('line'),
      color: Colors.red.shade200,
      width: 4,
      points: [customerLatLng!, providerLatLng!],
    );

    final distanceInMeters = Geolocator.distanceBetween(
      customerLatLng!.latitude,
      customerLatLng!.longitude,
      providerLatLng!.latitude,
      providerLatLng!.longitude,
    );

    setState(() {
      markers = updatedMarkers;
      polyline = poly;
      distanceText = '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
    });

    final bounds = LatLngBounds(
      southwest: LatLng(
        customerLatLng!.latitude < providerLatLng!.latitude
            ? customerLatLng!.latitude
            : providerLatLng!.latitude,
        customerLatLng!.longitude < providerLatLng!.longitude
            ? customerLatLng!.longitude
            : providerLatLng!.longitude,
      ),
      northeast: LatLng(
        customerLatLng!.latitude > providerLatLng!.latitude
            ? customerLatLng!.latitude
            : providerLatLng!.latitude,
        customerLatLng!.longitude > providerLatLng!.longitude
            ? customerLatLng!.longitude
            : providerLatLng!.longitude,
      ),
    );

    mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  void _startLiveLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions permanently denied');
      return;
    }

    final String docIdToUpdate = widget.isCurrentUserCustomer
        ? widget.customerId
        : widget.providerId;


    positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      print("📍 Updating $docIdToUpdate: ${position.latitude}, ${position.longitude}");

      FirebaseFirestore.instance
          .collection('user')
          .doc(docIdToUpdate)
          .update({
        'location': GeoPoint(position.latitude, position.longitude),
        'timeStamp': FieldValue.serverTimestamp(),
      }).then((_) {
        print("✅ Updated Firestore for $docIdToUpdate");
      }).catchError((e) {
        print("❌ Error updating Firestore: $e");
      });
    });
  }

  @override
  void dispose() {
    customerSub?.cancel();
    providerSub?.cancel();
    positionStream?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final polylines = polyline != null ? {polyline!} : <Polyline>{};

    return Scaffold(
      appBar: AppBar(title: const Text('Live Map View')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(23.8103, 90.4125),
              zoom: 16,
            ),
            markers: Set<Marker>.of(markers.values),
            polylines: polylines,
            onMapCreated: (controller) {
              mapController = controller;
              if (customerLatLng != null && providerLatLng != null) {
                _updateMap();
              }
            },
          ),
          if (distanceText != null)
            Positioned(
              bottom: 35,
              left: 15,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red, width: 2),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Distance: $distanceText',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<BitmapDescriptor> createCustomMarker(String text) async {
    final PictureRecorder pictureRecorder = PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double size = 150.0;

    final Paint paint = Paint()..color = Colors.blue;
    final Radius radius = const Radius.circular(20);

    final RRect rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size, size / 2),
      topLeft: radius,
      topRight: radius,
      bottomLeft: radius,
      bottomRight: radius,
    );

    canvas.drawRRect(rrect, paint);

    TextPainter textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    textPainter.text = TextSpan(
      text: text,
      style: const TextStyle(
        fontSize: 40,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );

    textPainter.layout(minWidth: 0, maxWidth: size);
    textPainter.paint(
      canvas,
      Offset((size - textPainter.width) / 2,
          (size / 4 - textPainter.height / 2)),
    );

    final img =
    await pictureRecorder.endRecording().toImage(size.toInt(), (size / 2).toInt());
    final data = await img.toByteData(format: ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }
}
