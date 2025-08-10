import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/location_helper.dart';
import 'menu.dart';

class ProviderAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Future<void> Function()? onLogout;

  const ProviderAppBar({super.key, this.onLogout});

  @override
  State<ProviderAppBar> createState() => _ProviderAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ProviderAppBarState extends State<ProviderAppBar> with WidgetsBindingObserver {
  bool _isSwitched = false;
  bool _isLoading = false;

  Timer? _heartbeatTimer;

  void startHeartbeat(String providerId, List<String> serviceIds) {
    _heartbeatTimer?.cancel(); // Avoid duplicate timers
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      for (String serviceId in serviceIds) {
        print(serviceId);
        FirebaseFirestore.instance
            .collection('service_provider')
            .doc(serviceId)
            .collection('providers')
            .doc(providerId)
            .update({'timestamp': FieldValue.serverTimestamp()});
      }
    });
  }

  void stopHeartbeat() {
    _heartbeatTimer?.cancel();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restoreOnlineState();
  }

  Future<void> _restoreOnlineState() async {
    final prefs = await SharedPreferences.getInstance();
    final providerId = prefs.getString('user_id');
    final serviceIds = prefs.getStringList('service_ids');

    if (providerId != null && serviceIds != null && serviceIds.isNotEmpty) {
      final snapshot = await FirebaseFirestore.instance
          .collection('service_provider')
          .doc(serviceIds.first)
          .collection('providers')
          .doc(providerId)
          .get();

      if (snapshot.exists) {
        setState(() => _isSwitched = true);
        startHeartbeat(providerId, serviceIds);
      }
    }
  }

  @override
  void dispose() {
    stopHeartbeat();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isSwitched) {
      SharedPreferences.getInstance().then((prefs) {
        final providerId = prefs.getString('user_id');
        final serviceIds = prefs.getStringList('service_ids');
        if (providerId != null && serviceIds != null && serviceIds.isNotEmpty) {
          startHeartbeat(providerId, serviceIds);
        }
      });
    }
  }

  Future<void> toggleOnlineStatus(bool value) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final providerId = prefs.getString('user_id');
    final serviceIds = prefs.getStringList('service_ids');

    if (providerId == null || serviceIds == null || serviceIds.isEmpty) {
      _showMessage('You have no service enabled yet. Please enable at least one service.', 'error');
      setState(() => _isLoading = false);
      return;
    }

    if (value) {
      await goOnline(providerId, serviceIds);
      startHeartbeat(providerId, serviceIds);
      _showMessage('You are now online.', 'success');
    } else {
      await goOffline(providerId, serviceIds);
      stopHeartbeat();
      _showMessage('You are now offline.', 'info');
    }

    setState(() {
      _isSwitched = value;
      _isLoading = false;
    });
  }

  Future<void> goOnline(String providerId, List<String> serviceIds) async {
    final position = await getCurrentLocation();

    for (String serviceId in serviceIds) {
      try {
        // Convert serviceId to int
        int parsedServiceId = int.tryParse(serviceId) ?? -1;
        int customerIdInt = int.tryParse(providerId) ?? -1;
        if (parsedServiceId == -1) {
          print('Invalid service ID: $serviceId');
          return;
        }

        await FirebaseFirestore.instance
            .collection('service_providers')
            .doc(serviceId)
            .collection('providers')
            .doc(providerId)
            .set({
          'provider_id': customerIdInt,
          'service_id': parsedServiceId,
          'location': GeoPoint(position.latitude, position.longitude),
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error going online for service $serviceId: $e');
      }
    }
  }

  Future<void> goOffline(String providerId, List<String> serviceIds) async {
    for (String serviceId in serviceIds) {
      try {
        // await FirebaseFirestore.instance
        //     .collection('service_providers')
        //     .doc(serviceId)
        //     .collection('providers')
        //     .doc(providerId)
        //     .delete();
        // print('Provider removed from service $serviceId');
      } catch (e) {
        print('Error removing provider from service $serviceId: $e');
      }
    }
  }

  // This method handles cleanup on logout
  Future<void> logoutCleanup() async {
    final prefs = await SharedPreferences.getInstance();
    final providerId = prefs.getString('user_id');
    final serviceIds = prefs.getStringList('service_ids');

    if (providerId != null && serviceIds != null && serviceIds.isNotEmpty) {
      await goOffline(providerId, serviceIds);
      stopHeartbeat();
      setState(() {
        _isSwitched = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Icon(
            _isSwitched ? Icons.wifi : Icons.wifi_off,
            color: _isSwitched ? Colors.green : Colors.redAccent,
          ),
          const SizedBox(width: 15),
          Text(
            _isSwitched ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: _isSwitched ? Colors.green : Colors.redAccent,
            ),
          ),
          const SizedBox(width: 15),
          Switch(
            value: _isSwitched,
            activeColor: Colors.green,
            inactiveThumbColor: Colors.redAccent,
            onChanged: _isLoading
                ? null
                : (val) async {
              FocusScope.of(context).unfocus();
              await toggleOnlineStatus(val);
            },
          )
        ],
      ),
      actions: [
        ProviderMenu(onLogout: logoutCleanup),
      ],
    );
  }

  void _showMessage(String msg, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: type == 'success'
            ? Colors.green.withAlpha(128)
            : Colors.red.withAlpha(128),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: type == 'success' ? Colors.green : Colors.red,
            width: 2,
          ),
        ),
        content: Text(
          msg,
          style: TextStyle(
            color: type == 'success' ? Colors.green : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
