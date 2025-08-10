import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  List<String> selectedServiceIds = [];
  bool isAdding = true;
  String searchQuery = '';
  String userId = '';

  @override
  void initState() {
    super.initState();
    loadSelectedServices();
  }

  Future<void> loadSelectedServices() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedServiceIds = prefs.getStringList('service_ids') ?? [];
      userId = prefs.getString('user_id') ?? '';
    });
  }

  Future<void> saveSelectedServices() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('service_ids', selectedServiceIds);
  }

  void addService(String serviceId) {
    if (!selectedServiceIds.contains(serviceId)) {
      setState(() {
        selectedServiceIds.add(serviceId);
        saveSelectedServices();
      });
    }
  }

  List<Map<String, dynamic>> get filteredServices {
    if (searchQuery.isEmpty) return [];
    return services
        .where((s) =>
    s['title'].toLowerCase().contains(searchQuery.toLowerCase()) &&
        !selectedServiceIds.contains(s['id']))
        .toList();
  }

  List<Map<String, dynamic>> get selectedServiceDetails =>
      services.where((s) => selectedServiceIds.contains(s['id'])).toList();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Available Services $userId',
                style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold,color: Colors.black87,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  setState(() {
                    isAdding = !isAdding;
                  });
                },
                icon: const Icon(Icons.add_circle_outline, size: 28, color: Colors.blue),
              ),
            ],
          ),
          if (isAdding) ...[
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search for a service...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 8),
            ...filteredServices.map((service) => ListTile(
              leading: Icon(service['icon'], color: service['color']),
              title: Text(service['title']),
              trailing: ElevatedButton(
                onPressed: () => addService(service['id']),
                child: const Text('Add'),
              ),
            )),
            const SizedBox(height: 16),
          ],
          const Text(
            'Your Selected Services',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          if (selectedServiceDetails.isEmpty)
            const Text('No services selected yet.'),
          ...selectedServiceDetails.map((service) {
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
                subtitle: Text(service['description']),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      selectedServiceIds.remove(service['id']);
                      saveSelectedServices();
                    });
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
