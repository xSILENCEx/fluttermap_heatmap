import 'package:flutter/material.dart';

class HeatMapOptions {
  HeatMapOptions(
      {this.radius = 30,
      this.minOpacity = 0.3,
      double blurFactor = 0.5,
      double layerOpacity = 0.75,
      Map<double, Color>? gradient})
      : gradient = gradient ?? defaultGradient,
        layerOpacity = layerOpacity >= 0 && layerOpacity <= 1 ? layerOpacity : 0.75,
        blurFactor = blurFactor >= 0 && blurFactor <= 1 ? blurFactor : 0.75;
  static final Map<double, Color> defaultGradient = <double, Color>{
    0.25: Colors.blue,
    0.55: Colors.green,
    0.85: Colors.yellow,
    1.0: Colors.red
  };

  /// Opacity of the heatmap layer when displayed on a map
  double layerOpacity;

  /// Default radius size applied during the painting of each point.
  double radius;

  /// Color gradient used for the heat map
  Map<double, Color> gradient;

  /// the minimum opacity used when calculating the heatmap of an area. accepts a number
  /// between 0 and 1.
  double? minOpacity;

  /// The blur factor applied during the painting of each point. the higher the number the higher
  /// the intensity.
  /// accepts a number value between 0 and 1.
  double blurFactor;
}

@immutable
class HeatMapDataPoint {
  const HeatMapDataPoint(this.x, this.y, {this.intensity = 1});

  /// x coordinate of the [HeatMapDataPoint]
  final double x;

  /// y coordinate of the [HeatMapDataPoint]
  final double y;

  /// intensity of the [HeatMapDataPoint] defaulting to 1
  final double intensity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatMapDataPoint &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y &&
          intensity == other.intensity;

  @override
  int get hashCode => Object.hash(x, y, intensity);

  HeatMapDataPoint merge(double x, double y, double intensity) {
    final double newX = (x * intensity + this.x * this.intensity) / intensity + this.intensity;
    final double newY = (y * intensity + this.y * this.intensity) / intensity + this.intensity;
    final double newIntensity = this.intensity + intensity;

    return HeatMapDataPoint(newX, newY, intensity: newIntensity);
  }
}
