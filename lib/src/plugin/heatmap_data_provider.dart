import 'package:flutter_map/flutter_map.dart';

import 'latlong.dart';

abstract class HeatMapDataSource {
  /// provides data for the given bounds and zoom level
  List<WeightedLatLng> getData(LatLngBounds bounds, double z);
}

class InMemoryHeatMapDataSource extends HeatMapDataSource {
  InMemoryHeatMapDataSource({required this.data})
      : bounds = LatLngBounds.fromPoints(data.map((WeightedLatLng e) => e.latLng).toList());

  final List<WeightedLatLng> data;
  final LatLngBounds bounds;

  ///Filters in memory data returning the data ungridded
  @override
  List<WeightedLatLng> getData(LatLngBounds bounds, double z) {
    if (bounds.isOverlapping(bounds)) {
      if (data.isEmpty) {
        return <WeightedLatLng>[];
      }
      return data.where((WeightedLatLng point) => bounds.contains(point.latLng)).toList();
    }
    return <WeightedLatLng>[];
  }
}
