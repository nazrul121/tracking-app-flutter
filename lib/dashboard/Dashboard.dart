import 'package:flutter/material.dart';
import 'package:gmap_tracking/dashboard/my_location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../auth/login.dart';
import 'user_list.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  String user_id = '';
  String username = '';

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginPage()), (route) => false,
    );
  }


  @override
  void initState() {
    super.initState();
    _loginData();
  }

  Future<void> _loginData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');
    String? userName = prefs.getString('username');

    if (userId != null) {
      setState(() {
        username = userName ?? 'User';
        user_id = userId;
      });
    }else{
      setState(() {
        username = 'Guest';
      });
    }
  }

  // Navigation method
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Method to render selected screen
  Widget _getSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return _buildHome();
      case 1:
        return UserList();
      case 2:
        return  MyLocation();
      default:
        return _buildHome();
    }
  }

  int _selectedIndex = 0;

  // Example data or widgets for each tab
  Widget _buildHome() {
    return Center(
      child: Center(
        child: Column(
          children: [
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Welcome ',
                    style: TextStyle(fontSize: 20, color: Colors.black),
                  ),
                  TextSpan(
                    text: username,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
              ),
            )
          ],
        ),
      )
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(username),
        actions: [
          IconButton(
            icon: Icon(Icons.logout,color: Colors.red,),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(child: _getSelectedScreen()),
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.not_listed_location_sharp),
            label: 'Location',
          ),
        ]
      )
    );
  }
}
