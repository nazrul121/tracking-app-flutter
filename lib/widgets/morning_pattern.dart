import 'package:flutter/material.dart';

class MorningPattern extends StatelessWidget {
  final double height;

  const MorningPattern({super.key, this.height = 180});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.colorScheme.surface.withOpacity(0.1);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            // Layer 1 - Far hills
            Align(
              alignment: Alignment.bottomCenter,
              child: ClipPath(
                clipper: _HillClipper1(),
                child: Container(
                  height: height * 0.8,
                  color: baseColor.withOpacity(0.3),
                ),
              ),
            ),
            // Layer 2 - Near hills
            Align(
              alignment: Alignment.bottomCenter,
              child: ClipPath(
                clipper: _HillClipper2(),
                child: Container(
                  height: height,
                  color: baseColor.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _HillClipper1 extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height - 30);
    path.quadraticBezierTo(size.width * 0.25, size.height - 60, size.width * 0.5, size.height - 20);
    path.quadraticBezierTo(size.width * 0.75, size.height, size.width, size.height - 40);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _HillClipper2 extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height - 20);
    path.quadraticBezierTo(size.width * 0.3, size.height - 50, size.width * 0.6, size.height - 10);
    path.quadraticBezierTo(size.width * 0.85, size.height + 20, size.width, size.height - 20);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
