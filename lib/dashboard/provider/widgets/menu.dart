
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:gmap_tracking/dashboard/provider/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/login.dart';

class ProviderMenu extends StatelessWidget {
  final Future<void> Function()? onLogout;

  const ProviderMenu({super.key, this.onLogout});

  Future<void> logout(BuildContext context) async {
    // If a callback was passed, run it first (for cleanup)
    if (onLogout != null) {
      await onLogout!();
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }


  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      tooltip: 'Menu',
      offset: const Offset(0, kToolbarHeight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      elevation: 8,
      icon: const Icon(Icons.more_vert, color: Colors.black),
      itemBuilder: (context) => [
        _buildItem(Icons.person, 'Profile', 0),
        _buildItem(Icons.history, 'History', 1),
        _buildItem(Icons.settings, 'Settings', 2),
        const PopupMenuDivider(),
        _buildItem(Icons.logout, 'Logout', 3),
      ],
      onSelected: (value) async {
        switch (value) {
          case 0:
          // Navigate to Profile page
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProviderHome()));
            break;
          case 1:
          // Navigate to History page
          //   Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryPage()));
            break;
          case 2:
          // Navigate to Settings page
          //   Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
            break;
          case 3:
          // Logout logic
            await logout(context);  // call your logout method here
            break;
        }
      },
    );
  }

  PopupMenuItem<int> _buildItem(IconData icon, String title, int value) {
    return PopupMenuItem<int>(
      value: value,
      child: Row(
        children: [

          Icon(icon,color: icon==Icons.logout? Colors.red: Colors.black54),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(color: title=='Logout'? Colors.red: Colors.black54),),
        ],
      ),
    );
  }
}
