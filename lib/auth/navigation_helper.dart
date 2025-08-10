import 'package:flutter/material.dart';
import 'package:gmap_tracking/dashboard/customer/home.dart';
import 'package:gmap_tracking/dashboard/provider/home.dart';


Future<void> navigateBasedOnUserType(BuildContext context, String type) async {
  print(type);
  if (type == 'customer') {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const CustomerHome()),
    );
  } else if (type == 'provider') {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ProviderHome()),
    );
  } else {
    // You can handle unknown types here or throw an error
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unknown user type'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

