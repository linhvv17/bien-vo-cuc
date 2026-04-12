import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated wave lines behind content (low opacity, non-interactive).
class WavesBackground extends StatefulWidget {
  const WavesBackground({super.key});

  @override
  State<WavesBackground> createState() => _WavesBackgroundState();
}

class _WavesBackgroundState extends State<WavesBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _WavesPainter(t: _controller.value),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _WavesPainter extends CustomPainter {
  _WavesPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0D1B2A);
    canvas.drawRect(Offset.zero & size, bg);

    void wave(Color color, double amp, double baseY, double freq) {
      final p = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2;
      final path = Path();
      for (double x = 0; x <= size.width; x += 8) {
        final y = baseY +
            (amp * (1.0 + 0.35 * (1 - x / size.width))) *
                math.sin((x / size.width) * freq * 6.283 + t * 6.283);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, p);
    }

    final y1 = size.height * 0.20;
    final y2 = size.height * 0.32;
    wave(const Color(0x334A90C4), 10, y1, 1.6);
    wave(const Color(0x33E8834A), 14, y2, 1.2);
  }

  @override
  bool shouldRepaint(covariant _WavesPainter oldDelegate) => oldDelegate.t != t;
}
