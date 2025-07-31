import 'package:flutter/material.dart';

import '../my_location.dart';

class ProviderHomeContent extends StatefulWidget {
  const ProviderHomeContent({super.key});

  @override
  State<ProviderHomeContent> createState() => _ProviderHomeContentState();
}

class _ProviderHomeContentState extends State<ProviderHomeContent> {
  bool _isSwitched = false;
  @override
  Widget build(BuildContext context) {
    return  Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // <-- Key part
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Icon(
                        _isSwitched ? Icons.wifi : Icons.wifi_off,
                        color: _isSwitched ? Colors.green : Colors.redAccent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isSwitched ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _isSwitched ? Colors.green : Colors.redAccent,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _isSwitched,
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.redAccent,
                        onChanged: (newValue) {
                          setState(() {
                            _isSwitched = newValue;
                          });
                        },
                      ),
                    ],
                  ),
                )
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end, // <-- Push to right
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.settings, size: 35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          MyLocation(),
        ],
    );
  }
}
