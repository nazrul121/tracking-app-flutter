import 'package:flutter/material.dart';
import 'package:gmap_tracking/dashboard/customer/widgets/menu.dart';
import 'package:gmap_tracking/dashboard/customer/widgets/services.dart';
import 'package:gmap_tracking/dashboard/my_location.dart';

class CustomerHome extends StatefulWidget {
  const CustomerHome({super.key});

  @override
  State<CustomerHome> createState() => _CustomerHomeState();
}

class _CustomerHomeState extends State<CustomerHome> {
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
    Center(child: MyLocation() ),
    Center(child: CustomerServicePage() ),
    Center(child: Text('Account Page')),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Home'),
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
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ]
                : [],
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
