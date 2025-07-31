import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../utils/location_helper.dart';

class ProviderServicePage extends StatefulWidget {
  const ProviderServicePage({super.key});

  @override
  State<ProviderServicePage> createState() => _ProviderServicePageState();
}

class _ProviderServicePageState extends State<ProviderServicePage> {
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
                  // Handle service tap if needed
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Future<void> handleServiceRequest({
    required String customerId,
    required String serviceId,
    required String serviceName,
  }) async {
    GeoPoint location = await getCurrentLocation();

    await FirebaseFirestore.instance
        .collection('service_request')
        .doc(customerId)
        .set({
      'service_id': serviceId,
      'service_name': serviceName,
      'timestamp': Timestamp.now(),
      'location': location,
    });

    // Now search for nearby providers
    searchNearbyProviders(
      customerId: customerId,
      serviceId: serviceId,
      customerLocation: location,
      serviceName: serviceName,
    );
  }

  Future<void> searchNearbyProviders({
    required String customerId,
    required String serviceId,
    required GeoPoint customerLocation,
    required String serviceName,
  }) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('service_provider')
        .doc(serviceId)
        .collection('active')
        .get();

    for (var doc in snapshot.docs) {
      GeoPoint providerLocation = doc['location'];

      double distance = calculateDistance(
          customerLocation.latitude,
          customerLocation.longitude,
          providerLocation.latitude,
          providerLocation.longitude);

      if (distance <= 5.0) {
        // Send notification or create a Firestore trigger for popup
        await FirebaseFirestore.instance
            .collection('provider_notifications')
            .doc(doc['provider_id'])
            .set({
          'customer_id': customerId,
          'service_id': serviceId,
          'service_name': serviceName,
          'timestamp': Timestamp.now(),
          'location': customerLocation,
        });

        break; // only notify one for now
      }
    }
  }


  double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
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
