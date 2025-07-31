import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationUploader {
  final String userId;
  StreamSubscription<Position>? _positionStream;

  LocationUploader(this.userId);

  void startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;
    }

    // Cancel any existing stream to prevent duplicates
    await _positionStream?.cancel();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1,
      ),
    ).listen((Position position) {
      FirebaseFirestore.instance.collection('user').doc(userId).set({
        'location': GeoPoint(position.latitude, position.longitude),
        'timeStamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print("Uploaded: ${position.latitude}, ${position.longitude}");
    });
  }

  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    print('Location tracking stopped.');
  }
}
