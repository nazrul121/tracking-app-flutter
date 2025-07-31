import 'dart:math';
import 'package:flutter/material.dart';

class FlyingBirds extends StatefulWidget {
  final double topOffset; // Allows you to place birds at different vertical positions
  const FlyingBirds({super.key, this.topOffset = 50});

  @override
  State<FlyingBirds> createState() => _FlyingBirdsState();
}

class _FlyingBirdsState extends State<FlyingBirds> with SingleTickerProviderStateMixin {
  late final AnimationController _birdController;
  late final Animation<double> _birdFlight;

  @override
  void initState() {
    super.initState();
    _birdController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _birdFlight = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _birdController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _birdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.topOffset,
      left: 0,
      right: 0,
      height: 100, // Adjust based on how tall you want the birds area
      child: AnimatedBuilder(
        animation: _birdFlight,
        builder: (context, _) => CustomPaint(
          painter: BirdsPainter(progress: _birdFlight.value),
        ),
      ),
    );
  }
}


class BirdsPainter extends CustomPainter {
  final double progress;
  BirdsPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint birdPaint = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final x = size.width * (progress + i * 0.25) % size.width;
      final y = 90 + 20 * sin((progress * 2 * pi) + i);
      final path = Path();
      path.moveTo(x, y);
      path.relativeQuadraticBezierTo(4, -4, 8, 0);
      path.moveTo(x + 8, y);
      path.relativeQuadraticBezierTo(4, -4, 8, 0);
      canvas.drawPath(path, birdPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BirdsPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
