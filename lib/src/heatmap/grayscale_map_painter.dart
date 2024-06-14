import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart' hide Image;

/// Painter for creating a grayscale version of the heatmap by painting the base image
/// for each provided data point.
class GrayScaleHeatMapPainter extends CustomPainter {
  GrayScaleHeatMapPainter(
      {required this.baseCircle, this.buffer = 0, required this.data, double? minOpacity, this.min, this.max})
      : minOpacity = minOpacity ?? 0.3;

  double minOpacity = 0.3;
  final Image baseCircle;
  double? min;
  double? max;
  double buffer;
  final List<DataPoint> data;

  @override
  void paint(Canvas canvas, Size size) {
    if (min == null || max == null) {
      min = 0;
      max = 2;
    }

    final Paint paint = Paint()..color = const Color.fromRGBO(0, 0, 0, 1);

    // offsets for centering the baseCircle when painting
    final double yOffset = baseCircle.height / 2;
    final double xOffset = baseCircle.width / 2;
    for (final DataPoint point in data) {
      final double alpha = math.min(math.max(point.z / max!, minOpacity), 1.0);

      paint.color = Color.fromRGBO(0, 0, 0, alpha);

      canvas.drawImage(baseCircle, Offset(point.x + buffer - xOffset, point.y + buffer - yOffset), paint);
    }
  }

  @override
  bool shouldRepaint(GrayScaleHeatMapPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

/// data point representing an x, y coordinate with an intensity
class DataPoint {
  DataPoint(this.x, this.y, this.z);

  factory DataPoint.fromOffset(Offset offset) {
    return DataPoint(offset.dx, offset.dy, 1);
  }

  double x;
  double y;
  double z;

  void merge(double x, double y, double intensity) {
    this.x = (x * intensity + this.x * z) / (intensity + z);
    this.y = (y * intensity + this.y * z) / (intensity + z);
    z = z + intensity;
  }
}
