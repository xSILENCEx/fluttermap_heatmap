import 'dart:math' as math;
import 'package:flutter/material.dart' hide Image;

class AltBaseCirclePainter extends CustomPainter {
  const AltBaseCirclePainter({required this.radius, this.blurFactor = 0.5});

  /// radius of the circle to be painted
  final double radius;

  /// radius of the gradient applied to the painted circle
  final double blurFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double r2 = radius;

    final Rect rect = Rect.fromPoints(Offset(width / 2 - r2, height / 2 - r2), Offset(width / 2 + r2, height / 2 + r2));

    final Shader gradient = RadialGradient(
            colors: const <Color>[Color.fromRGBO(0, 0, 0, 1), Color.fromRGBO(0, 0, 0, 0)],
            stops: const <double>[0, 1],
            radius: blurFactor)
        .createShader(rect);

    canvas.drawPath(
      Path()
        ..addArc(rect, 0, math.pi * 2)
        ..close(),
      Paint()..shader = gradient,
    );
  }

  @override
  bool shouldRepaint(AltBaseCirclePainter oldDelegate) {
    return false;
  }
}
