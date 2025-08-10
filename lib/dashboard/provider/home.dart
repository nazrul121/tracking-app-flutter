import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Source;
import 'package:flutter/material.dart';
import 'package:gmap_tracking/dashboard/provider/services/request_handler.dart';
import 'package:gmap_tracking/dashboard/provider/widgets/appBar.dart';
import 'package:gmap_tracking/dashboard/provider/widgets/incoming_request_dialog.dart';
import 'package:gmap_tracking/dashboard/provider/widgets/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'my_home.dart';

class ProviderHome extends StatefulWidget {
  const ProviderHome({super.key});

  @override
  State<ProviderHome> createState() => _ProviderHomeState();
}

class _ProviderHomeState extends State<ProviderHome> {
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
    ProviderHomeContent(),
    Center(child: ProviderServicePage() ),
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
    _startListeningForRequests();
  }

  StreamSubscription<QuerySnapshot>? _requestsSubscription;

  Future<void> _startListeningForRequests() async {

    print('start listening to customer request....');

    final prefs = await SharedPreferences.getInstance();
    final providerId = prefs.getString('user_id');

    if (providerId == null || providerId == -1) {
      print('Provider ID not found in SharedPreferences');
      return;
    }

    final int parsedProviderId = int.tryParse(providerId) ?? -1;
    if (parsedProviderId == -1) {
      print('Invalid provider ID');
      return;
    }
    await _requestsSubscription?.cancel();
    _requestsSubscription = FirebaseFirestore.instance
        .collection('provider_notifications')
        .where('provider_id', isEqualTo: parsedProviderId)
        .where('status', isEqualTo: 'new')
        .snapshots()
        .listen((querySnapshot) {


      for (var change in querySnapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final requestData = change.doc.data();
          print('New request received: $requestData.location');
          if (requestData != null) {
            _showIncomingRequestPopup(change.doc.id, requestData);
          }
        }
      }
    });
  }


  Future<void> _showIncomingRequestPopup(String requestId, Map<String, dynamic> requestData) async {

    if (!mounted) return;
    final RequestHandler requestHandler = RequestHandler();
    await requestHandler.playAlertSound();

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (_, __, ___) {
        return IncomingRequestDialog(
          requestData: requestData,
          onAccept: () async {
            Navigator.pop(context);
            await requestHandler.stopSound();
            await requestHandler.acceptRequest(requestId);
          },
          onIgnore: () async {
            Navigator.pop(context);
            await requestHandler.stopSound();
            await requestHandler.ignoreRequest(requestId);
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _requestsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final bool isNavBarVisible = bottomInset > 0;

    return isNavBarVisible ?
      SafeArea(
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: ProviderAppBar(),
          body:_buildMainWidget(),
          bottomNavigationBar: _bottomNavBarWidget(),
        ),
      )
      :Scaffold(
        extendBodyBehindAppBar: true,
        appBar: ProviderAppBar(),
        body: SafeArea(
          child: _buildMainWidget(),
        ),
        bottomNavigationBar: _bottomNavBarWidget(),
      )
    ;

  }

  Widget _buildMainWidget(){
    return SingleChildScrollView(
      child: Stack(
        children: [
          _pages[_selectedIndex],
        ],
      ),
    );
  }

  Widget _bottomNavBarWidget(){
    return Container(
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
            boxShadow: isSelected ? [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ] : [],
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

}
