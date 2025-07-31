import 'package:flutter/widgets.dart';
import 'package:gmap_tracking/services/location_updater.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLifecycleHandler extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    if (userId == null) return;

    LocationUploader locationUploader = LocationUploader(userId);
    if (state == AppLifecycleState.resumed) {
      locationUploader.startTracking();
    } else if (state == AppLifecycleState.paused) {
      locationUploader.stopTracking();
    }
  }
}
