import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../main.dart';
import '../../../utils/location_helper.dart';

class RequestServicePopup extends StatefulWidget {
  const RequestServicePopup({super.key});

  @override
  State<RequestServicePopup> createState() => _RequestServicePopupState();
}

class _RequestServicePopupState extends State<RequestServicePopup> {
  final List<Map<String, dynamic>> services = [
    {
      'id': '1',
      'icon': Icons.headset_mic_outlined,
      'title': '24/7 Support',
      'description': 'We are here to help you any time, day or night.',
      'color': Colors.blue,
    },
    {
      'id': '2',
      'icon': Icons.security_outlined,
      'title': 'Secure Transactions',
      'description': 'Your data and payments are safe with us.',
      'color': Colors.green,
    },
    {
      'id': '3',
      'icon': Icons.local_shipping_outlined,
      'title': 'Fast Delivery',
      'description': 'Quick and reliable delivery services.',
      'color': Colors.orange,
    },
    {
      'id': '4',
      'icon': Icons.thumb_up_alt_outlined,
      'title': 'Quality Assurance',
      'description': 'We ensure top quality services at all times.',
      'color': Colors.purple,
    },
  ];

  final List<dynamic> distanceOptions = [5.0, 10.0, 20.0, 'any'];
  dynamic selectedDistance = 5.0;
  bool isLoading = false;


  Map<String, dynamic>? selectedService;

  String user_id = '';

  @override
  void initState() {
    super.initState();
    getUserInfo();
  }

  Future<void> getUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null) {
      setState(() {
        user_id = userId;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: selectedService == null
            ? MediaQuery.of(context).size.height * 0.7
            : MediaQuery.of(context).size.height * 0.45,
        child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.blue.withValues(alpha: 0.7), // Choose your desired color
                  width: 7,           // Set the desired width
                ),
              ),
              borderRadius: BorderRadius.circular(24),
            ),
          child: Column(
            children: [
              _buildHeader(),
              const Divider(height: 0),
              Expanded(
                child: selectedService == null
                    ? _buildServiceList()
                    : _buildServiceDetails(selectedService!),
              ),
            ],
          ),
        )
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          if (selectedService != null)
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() => selectedService = null),
            ),
          Expanded(
            child: Text(
              selectedService == null ? 'Choose a Service' : selectedService!['title'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceList() {
    return ListView.separated(
      itemCount: services.length,
      separatorBuilder: (_, __) => const Divider(height: 0),
      itemBuilder: (context, index) {
        final service = services[index];
        return ListTile(
          leading: Icon(service['icon'], color: service['color']),
          title: Text(service['title']),
          subtitle: Text(service['description']),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          onTap: () => setState(() => selectedService = service),
        );
      },
    );
  }

  Widget _buildServiceDetails(Map<String, dynamic> service) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(service['icon'], size: 48, color: service['color']),
          const SizedBox(height: 16),
          Text(
            service['title'],
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: service['color'],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            service['description'],
            style: const TextStyle(fontSize: 16),
          ),
          const Spacer(),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: service['color'],
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20)
              ),
              icon: DropdownButton<dynamic>(
                value: selectedDistance,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedDistance = value;
                    });
                  }
                },
                items: distanceOptions.map((option) {
                  return DropdownMenuItem<dynamic>(
                    value: option,
                    child: Text( style: TextStyle(color: Colors.black54),
                      option == 'any' ? 'Any km' : '${option.toInt()} km',
                    ),
                  );
                }).toList(),
              ),
              onPressed: () {
                handleServiceRequest(customerId: user_id, serviceId: service['id'], serviceName: service['title'], searchDistance: selectedDistance,);
              },
              label: isLoading?
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Searching...   ', style: TextStyle(color: Colors.white, ),),
                    SizedBox(width: 16,height: 16,
                    child:  CircularProgressIndicator(color: Colors.white70,backgroundColor: Colors.blueGrey,),)
                  ],
                )
                :Text('Search Providers', style: TextStyle(color: Colors.white, fontSize: 18),),
            ),
          ),
          SizedBox(height:20)
        ],
      ),
    );
  }


  Future<void> handleServiceRequest({
    required String customerId,
    required String serviceId,
    required String serviceName,
    required dynamic searchDistance,
  }) async {
    setState(() {
      isLoading = true;
    });
    GeoPoint location = await getCurrentLocation();
    int parsedServiceId = int.tryParse(serviceId) ?? -1;
    int parsedCustomerId = int.tryParse(customerId) ?? -1;

    if (parsedServiceId == -1 || parsedCustomerId == -1) {
      print('Invalid service or customer ID');
      return;
    }

    // Step 1: Try to notify providers
    bool providerFound = await searchNearbyProviders(
      customerId: customerId,
      serviceId: serviceId,
      customerLocation: location,
      serviceName: serviceName,
      searchDistance: searchDistance,
    );

    // Step 2: Only save service_request if provider was found
    if (providerFound) {
      await FirebaseFirestore.instance.collection('service_requests').add({
        'service_id': parsedServiceId,
        'service_name': serviceName,
        'timestamp': Timestamp.now(),
        'location': location,
        'status': 'new',
        'customer_id': parsedCustomerId,
      });

      showDialog(
        context: navigatorKey.currentContext!,
        builder: (_) => AlertDialog(
          title: const Text("Request Sent"),
          content: const Text("Your request is in progress. Please wait..."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(navigatorKey.currentContext!),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }
    else {
      showDialog(
        context: navigatorKey.currentContext!,
        builder: (_) => AlertDialog(
          title: const Text("No Provider Found"),
          content: const Text("No service provider is available at the moment."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(navigatorKey.currentContext!),
              child: const Text("OK"),
            ),
          ],
        ),
      );
    }

    setState(() {
      isLoading = false;
    });
  }



  Future<bool> searchNearbyProviders({
    required String customerId,
    required String serviceId,
    required GeoPoint customerLocation,
    required String serviceName,
    required dynamic searchDistance,
  })
  async {
    final int? parsedServiceId = int.tryParse(serviceId);
    final int? parsedCustomerId = int.tryParse(customerId);

    if (parsedServiceId == null || parsedCustomerId == null) {
      print('Invalid IDs');
      return false;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('service_providers')
        .doc(parsedServiceId.toString())
        .collection('providers')
        .get();

    for (var doc in snapshot.docs) {
      final GeoPoint providerLocation = doc['location'];

      final double distance = calculateDistance(
        customerLocation.latitude,
        customerLocation.longitude,
        providerLocation.latitude,
        providerLocation.longitude,
      );

      print('Distance to provider: $distance km | Search Distance: $searchDistance');

      // CASE 1: 'any' → Notify the first provider, regardless of distance
      if (searchDistance == 'any') {
        await FirebaseFirestore.instance.collection('provider_notifications').add({
          'provider_id': doc['provider_id'],
          'customer_id': parsedCustomerId,
          'service_id': parsedServiceId,
          'service_name': serviceName,
          'timestamp': Timestamp.now(),
          'distance': distance,
          'location': customerLocation,
          'status': 'new',
        });
        return true;
      }

      // CASE 2: Distance filtering
      if (distance <= (searchDistance as double)) {
        await FirebaseFirestore.instance.collection('provider_notifications').add({
          'provider_id': doc['provider_id'],
          'customer_id': parsedCustomerId,
          'service_id': parsedServiceId,
          'service_name': serviceName,
          'timestamp': Timestamp.now(),
          'distance': distance,
          'location': customerLocation,
          'status': 'new',
        });

        return true;
      }
    }

    return false; // No provider found
  }



  double calculateDistance( double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) *
            cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) /
            2;
    final distance = 12742 * asin(sqrt(a));
    print('distance between customer and provider $distance');
    return distance;
  }


}
