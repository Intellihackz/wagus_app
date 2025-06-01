import 'dart:math';
import 'package:flutter/material.dart';

class GlitchOverlay extends StatefulWidget {
  const GlitchOverlay({super.key});

  @override
  State<GlitchOverlay> createState() => _GlitchOverlayState();
}

class _GlitchOverlayState extends State<GlitchOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _offsetX = 0;
  double _opacity = 0.03;

  @override
  void initState() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..repeat();

    _controller.addListener(() {
      final rand = Random();
      setState(() {
        _offsetX = rand.nextDouble() * 8 - 4;
        _opacity = 0.02 + rand.nextDouble() * 0.05;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          // Scanlines
          Container(
            color: Colors.black.withOpacity(0.1),
            child: CustomPaint(
              painter: _ScanlinePainter(),
              size: Size.infinite,
            ),
          ),
          // Glitch jitter
          Transform.translate(
            offset: Offset(_offsetX, 0),
            child: Container(
              color: Colors.white.withOpacity(_opacity),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
