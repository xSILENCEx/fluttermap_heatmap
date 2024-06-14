import 'dart:math';
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

class GriddedHeatMapDataSource extends HeatMapDataSource {
  GriddedHeatMapDataSource({required this.data, required this.radius})
      : bounds = LatLngBounds.fromPoints(data.map((WeightedLatLng e) => e.latLng).toList());

  final List<WeightedLatLng> data;
  final LatLngBounds bounds;
  final Epsg3857 crs = const Epsg3857();
  final double radius;

  final Map<double, List<WeightedLatLng>> _gridCache = <double, List<WeightedLatLng>>{};

  ///Filters in memory data returning the data ungridded
  @override
  List<WeightedLatLng> getData(LatLngBounds bounds, double z) {
    if (data.isNotEmpty && bounds.isOverlapping(bounds)) {
      final List<WeightedLatLng> griddedData = _getGriddedData(z);

      if (griddedData.isEmpty) {
        return <WeightedLatLng>[];
      }
      return griddedData.where((WeightedLatLng point) => bounds.contains(point.latLng)).toList();
    }

    return <WeightedLatLng>[];
  }

  List<WeightedLatLng> _getGriddedData(double z) {
    if (_gridCache.containsKey(z)) {
      return _gridCache[z]!;
    }
    final Point<double> leftBound = crs.latLngToPoint(bounds.northWest, z);

    final Point<double> rightBound = crs.latLngToPoint(bounds.southEast, z);

    final Point<double> size = Bounds<double>(leftBound, rightBound).size;

    final double cellSize = radius / 2;

    final List<List<WeightedLatLng?>> grid = <List<WeightedLatLng?>>[]..length = (size.y / cellSize).ceil() + 2;

    final List<WeightedLatLng> griddedData = <WeightedLatLng>[];

    for (final WeightedLatLng point in data) {
      final Point<double> globalPixel = crs.latLngToPoint(point.latLng, z);
      final Point<double> pixel = Point<double>(globalPixel.x - leftBound.x, globalPixel.y - leftBound.y);

      final int x = ((pixel.x) ~/ cellSize) + 2;
      final int y = ((pixel.y) ~/ cellSize) + 2;

      grid[y] = grid[y]..length = (size.y / cellSize).ceil() + 2;
      WeightedLatLng? cell = grid[y][x];

      if (cell == null) {
        grid[y][x] = WeightedLatLng(point.latLng, 1);
        cell = grid[y][x];
      } else {
        cell.merge(point.latLng.longitude, point.latLng.latitude, 1);
      }
    }

    for (int i = 0, len = grid.length; i < len; i++) {
      for (int j = 0, len2 = grid[i].length; j < len2; j++) {
        final WeightedLatLng? cell = grid[i][j];
        if (cell != null) {
          griddedData.add(cell);
        }
      }
    }

    _gridCache[z] = griddedData;

    return griddedData;
  }
}
