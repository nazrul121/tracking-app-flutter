import 'package:flutter/material.dart';

import 'live_tracking_map.dart';

class UserList extends StatefulWidget {
  const UserList({super.key});

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  final List<Map<String, dynamic>> users = [
    {'id':'1','username': 'demo1', 'password': '123456', 'status': 1, 'type':'user'},
    {'id':'2','username': 'demo2', 'password': '123456', 'status': 0, 'type':'user'},
    {'id':'3','username': 'demo3', 'password': '123456', 'status': 1, 'type':'user'},
    {'id':'4','username': 'admin', 'password': '123456', 'status': 1, 'type':'admin'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User List"),
      ),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: users.map((user) {
            final username = user['username'] ?? 'Unknown';
            final userType = user['type'] ?? 'N/A';
            final status = user['status'] == 1 ? 'Active' : 'Inactive';

            return Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  child: Text(user['username'][0].toUpperCase()),
                ),
                title: Text(user['username'], style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Status: ${user['status'] == 1 ? "Active" : "Inactive"}'),
                trailing: ElevatedButton(
                  child: Text('View Live'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveTrackingMap(userId: user['id']),
                      ),
                    );
                  },
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
