import 'package:latlong2/latlong.dart';

/// wraps a LatLng with an intensity
class WeightedLatLng {
  WeightedLatLng(this.latLng, this.intensity, this.radius);

  LatLng latLng;
  double intensity;

  /// Default radius size applied during the painting of this point.
  double radius;

  @override
  String toString() {
    return 'WeightedLatLng{latLng: $latLng, intensity: $intensity}';
  }

  /// merge weighted lat long value the current WeightedLatLng,
  void merge(double x, double y, double intensity) {
    final double newX = (x * intensity + latLng.longitude * this.intensity) / (intensity + this.intensity);
    final double newY = (y * intensity + latLng.latitude * this.intensity) / (intensity + this.intensity);
    latLng = LatLng(newY, newX);
    this.intensity += intensity;
  }
}
