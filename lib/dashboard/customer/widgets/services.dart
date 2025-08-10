import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../utils/location_helper.dart';

class CustomerServicePage extends StatefulWidget {
  const CustomerServicePage({super.key});

  @override
  State<CustomerServicePage> createState() => _CustomerServicePageState();
}

class _CustomerServicePageState extends State<CustomerServicePage> {
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Services',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...services.map((service) {
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: service['color'].withOpacity(0.15),
                  radius: 28,
                  child: Icon(
                    service['icon'],
                    color: service['color'],
                    size: 28,
                  ),
                ),
                title: Text(
                  service['title'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['description'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () {
                  // handleServiceRequest(customerId: user_id, serviceId: service['id'], serviceName: service['title']);
                },
              ),
            );
          }),
        ],
      ),
    );
  }


  Future<void> handleServiceRequest({
    required String customerId,
    required String serviceId,
    required String serviceName,
  })
  async {
    GeoPoint location = await getCurrentLocation();

    // Convert serviceId to int
    int parsedServiceId = int.tryParse(serviceId) ?? -1;
    int customerIdInt = int.tryParse(customerId) ?? -1;
    if (parsedServiceId == -1) {
      print('Invalid service ID: $serviceId');
      return;
    }

    await FirebaseFirestore.instance
        .collection('service_requests')
        .add({
      'service_id': parsedServiceId,
      'service_name': serviceName,
      'timestamp': Timestamp.now(),
      'location': location,
      'status': 'new',
      'customer_id': customerIdInt,
    });

    // Now search for nearby providers
    searchNearbyProviders(
      customerId: customerId,
      serviceId: parsedServiceId.toString(), // keep passing string if needed
      customerLocation: location,
      serviceName: serviceName,
    );
  }

  Future<void> searchNearbyProviders({
    required String customerId,
    required String serviceId,
    required GeoPoint customerLocation,
    required String serviceName,
  })
  async {
    final int? parsedServiceId = int.tryParse(serviceId);
    final int? parsedCustomerId = int.tryParse(customerId);

    if (parsedServiceId == null || parsedCustomerId == null) {
      print('Invalid serviceId or customerId format');
      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('service_providers')
        .doc(parsedServiceId.toString()) // doc ID can stay string
        .collection('providers')
        .get();

    for (var doc in snapshot.docs) {
      // GeoPoint providerLocation = doc['location'];
      //
      // double distance = calculateDistance(
      //   customerLocation.latitude,
      //   customerLocation.longitude,
      //   providerLocation.latitude,
      //   providerLocation.longitude,
      // );

      // if (distance <= 5.0) {
      await FirebaseFirestore.instance
          .collection('provider_notifications')
          .add({
        'provider_id': doc['provider_id'],
        'customer_id': parsedCustomerId,
        'service_id': parsedServiceId,
        'service_name': serviceName,
        'timestamp': Timestamp.now(),
        'location': customerLocation,
        'status': 'new',
      });
      print('sent request to provider');
      break; // notify only one for now
      // }
    }
  }



  double calculateDistance( double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) *
            cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // in km
  }


}
