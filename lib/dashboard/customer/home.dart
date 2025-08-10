import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gmap_tracking/dashboard/customer/widgets/menu.dart';
import 'package:gmap_tracking/dashboard/customer/widgets/my_location.dart';
import 'package:gmap_tracking/dashboard/customer/widgets/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lifecycle_handler.dart';
import 'customer_providerOn_map.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> with WidgetsBindingObserver{
  final AppLifecycleHandler _lifecycleHandler = AppLifecycleHandler();

  int _selectedIndex = 0;

  final List<String> _titles = ['Home', 'Service', 'Account'];
  final List<IconData> _iconsFilled = [
    Icons.home_filled,
    Icons.build_circle,
    Icons.account_circle,
  ];

  final List<IconData> _iconsOutlined = [
    Icons.home_outlined,
    Icons.build_circle_outlined,
    Icons.account_circle_outlined,
  ];

  // List of pages to show for each tab
  final List<Widget> _pages = [
    Center(child: CustomerLocation() ),
    Center(child: CustomerServicePage() ),
    Center(child: Text('Account Page')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _getUserData();
    _startListeningFromProvider();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addObserver(_lifecycleHandler);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground, re-check location permission/status
      _startListeningFromProvider();
    }
  }


  String userId = '';
  String userName = '';
  String name = '';
  String userPhone = '';
  String userAddress = '';

  Future<void> _getUserData() async{
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        userId = prefs.getString('user_id') ?? '';
        userName = prefs.getString('userName') ?? '';
        name = prefs.getString('name') ?? '';
        userPhone = prefs.getString('phone') ?? '';
        userAddress = prefs.getString('address') ?? '';
      });
    }
    catch(e){
      print(e);
    }
  }

  @override
  void dispose() {
    super.dispose();
    _requestsSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(_lifecycleHandler);
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name.toString()),
        actions: [CustomerMenu() ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _pages[_selectedIndex],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Row(
          children: List.generate(_titles.length, (index) => _buildNavItem(index)),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    bool isSelected = index == _selectedIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade100 : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: isSelected? [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ]: [],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? _iconsFilled[index] : _iconsOutlined[index],
                  color: isSelected ? Colors.blue : Colors.grey[600],
                  size: isSelected ? 28 : 24,
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Text(
                    _titles[index],
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }



  //listening response from provider replay
  StreamSubscription<QuerySnapshot>? _requestsSubscription;
  Future<void> _startListeningFromProvider() async {
    print('start listening from provider feedback....');

    final prefs = await SharedPreferences.getInstance();
    final customerId = prefs.getString('user_id');

    await _requestsSubscription?.cancel();

    _requestsSubscription = FirebaseFirestore.instance
        .collection('request_feedbacks')
        .where('customer_id', isEqualTo: customerId)
        .where('seen', isEqualTo: false)
        .snapshots()
        .listen((querySnapshot) async {
      for (var change in querySnapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final doc = change.doc;
          final docId = doc.id;
          print("Doc is: $docId");
          final requestData = doc.data();

          if (requestData != null ) {
            showFeedbackPopup(requestData, docId);
          }
        }
      }
    });
  }


  Future<void> showFeedbackPopup(Map<String, dynamic> requestData, String docId) async {
    // Prevent dismiss on tap outside or back button
    await showDialog(
      context: context,
      barrierDismissible: false, // <-- Important
      builder: (_) => AlertDialog(
        backgroundColor:  Colors.white70,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: requestData['status'] == 'accepted' ? Colors.green : Colors.deepOrange,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        title: Text(
          'Feedback',
          style: TextStyle(
            color: requestData['status'] == 'accepted' ? Colors.white : Colors.black,
          ),
        ),
        content: RichText(text: TextSpan(
          style: TextStyle(color: Colors.black),
          children: [
            TextSpan(text: 'Your request for ',style: TextStyle(fontSize: 18)),
            TextSpan(text:requestData['service_name'],style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextSpan(text: ' has been ',style: TextStyle(fontSize: 18)),
            TextSpan(text:requestData['status'],style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            TextSpan(text: ' By ',style: TextStyle(fontSize: 18)),
            TextSpan(text:"Provider name..",style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        )),
        actions: [
          if(requestData['status']=='accepted')
            TextButton(
              onPressed: () async {
                await _markFeedbackAsSeen(docId);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => DistanceCustomerProvider(
                      customerId: requestData['customer_id'].toString(),
                      providerId: requestData['provider_id'].toString(),
                      isCurrentUserCustomer: false,
                    ),
                  ),
                );
              },
              child: Text("View Map",style: TextStyle(color: Colors.black),),
            ),
          TextButton(
            onPressed: () async {
              await _markFeedbackAsSeen(docId); // <-- Update Firestore
              Navigator.of(context).pop(); // just close dialog
            },
            child: Text(requestData['status']=='ignored'?'OK': "Close",style: TextStyle(color: Colors.black),),
          ),
        ],
      ),
    );
  }

  Future<void> _markFeedbackAsSeen(String docId) async {
    await FirebaseFirestore.instance
        .collection('request_feedbacks')
        .doc(docId)
        .update({'seen': true});
  }


}
