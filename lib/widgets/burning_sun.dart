import 'package:flutter/material.dart';

class BurningSun extends StatefulWidget {
  final double screenWidth;
  const BurningSun({super.key, required this.screenWidth});

  @override
  State<BurningSun> createState() => _BurningSunState();
}

class _BurningSunState extends State<BurningSun>
    with SingleTickerProviderStateMixin {
  late AnimationController _sunController;
  late Animation<double> _sunOpacity;

  @override
  void initState() {
    super.initState();

    _sunController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _sunOpacity = Tween<double>(begin: 0.3, end: 0.6).animate(
      CurvedAnimation(parent: _sunController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sunController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sunOpacity,
      builder: (context, child) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Transform.translate(
            offset: Offset(0, widget.screenWidth * 0.66),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: widget.screenWidth * 1.2,
                  height: widget.screenWidth * 1.2,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.orange.withOpacity(_sunOpacity.value.clamp(0.5, 1.0)),
                        Colors.transparent,
                      ],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
