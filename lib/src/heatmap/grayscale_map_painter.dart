import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart' hide Image;

class ImageObj {
  ImageObj({
    required this.image,
    required this.offset,
    required this.alpha,
  });

  final Image image;
  final Offset offset;
  final double alpha;
}

/// Painter for creating a grayscale version of the heatmap by painting the base image
/// for each provided data point.
class GrayScaleHeatMapPainter extends CustomPainter {
  GrayScaleHeatMapPainter(
      {required this.getBaseCircle, this.buffer = 0, required this.data, double? minOpacity, this.min, this.max})
      : minOpacity = minOpacity ?? 0.3;

  double minOpacity = 0.3;
  final Future<Image> Function(double r) getBaseCircle;
  double? min;
  double? max;
  double buffer;
  final List<DataPoint> data;
  final List<ImageObj> images = <ImageObj>[];

  Future<void> ready() async {
    if (min == null || max == null) {
      min = 0;
      max = 2;
    }

    for (final DataPoint point in data) {
      final Image image = await getBaseCircle(point.r);
      final double alpha = math.min(math.max(point.z / max!, minOpacity), 1);
      final double yOffset = image.height / 2;
      final double xOffset = image.width / 2;

      images.add(
        ImageObj(image: image, offset: Offset(point.x + buffer - xOffset, point.y + buffer - yOffset), alpha: alpha),
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = const Color.fromRGBO(0, 0, 0, 1);

    for (final ImageObj img in images) {
      paint.color = Color.fromRGBO(0, 0, 0, img.alpha);
      canvas.drawImage(img.image, img.offset, paint);
    }
  }

  @override
  bool shouldRepaint(GrayScaleHeatMapPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

/// data point representing an x, y coordinate with an intensity
class DataPoint {
  DataPoint(this.x, this.y, this.z, this.r);

  double x;
  double y;
  double z;
  double r;

  void merge(double x, double y, double intensity) {
    this.x = (x * intensity + this.x * z) / (intensity + z);
    this.y = (y * intensity + this.y * z) / (intensity + z);
    z = z + intensity;
  }
}
