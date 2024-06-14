import 'dart:math' as math;
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:latlong2/latlong.dart';

class HeatMapTilesProvider extends TileProvider {
  HeatMapTilesProvider({required this.dataSource, required this.heatMapOptions});

  HeatMapDataSource dataSource;
  HeatMapOptions heatMapOptions;

  late Map<double, List<DataPoint>> griddedData;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final double tileSize = options.tileSize;

    // disable zoom level 0 for now. ned to refactor _filterData
    final List<DataPoint> filteredData = coordinates.z != 0 ? _filterData(coordinates, options) : <DataPoint>[];
    final double scale = coordinates.z / 22 * 1.22;
    final double radius = heatMapOptions.radius * scale;
    final HeatMapOptions imageHMOptions = HeatMapOptions(
      radius: radius,
      minOpacity: heatMapOptions.minOpacity,
      blurFactor: heatMapOptions.blurFactor,
      layerOpacity: heatMapOptions.layerOpacity,
      gradient: heatMapOptions.gradient,
    );

    return HeatMapImage(filteredData, imageHMOptions, tileSize);
  }

  /// hyperbolic sine implementation
  static double _sinh(double angle) {
    return (math.exp(angle) - math.exp(-angle)) / 2;
  }

  List<DataPoint> _filterData(TileCoordinates coords, TileLayer options) {
    final List<DataPoint> filteredData = <DataPoint>[];
    final int zoom = coords.z;
    final double scale = coords.z / 22 * 1.22;
    final double radius = 25 * scale;
    final double size = options.tileSize;
    final double maxZoom = options.maxZoom;
    final LatLngBounds bounds = _bounds(coords, 1);
    final List<WeightedLatLng> points = dataSource.getData(bounds, zoom.toDouble());
    final double v = 1 / math.pow(2, math.max(0, math.min(maxZoom - zoom, 12)));

    final double cellSize = radius / 2;

    final double gridOffset = size;
    final double gridSize = size + gridOffset;

    final int gridLength = (gridSize / cellSize).ceil() + 2 + gridOffset.ceil();
    final List<List<DataPoint?>> grid = List<List<DataPoint?>>.filled(gridLength, <DataPoint?>[], growable: true);

    const Epsg3857 crs = Epsg3857();

    final Point<double> tileOffset = Point<double>(options.tileSize * coords.x, options.tileSize * coords.y);
    for (final WeightedLatLng point in points) {
      if (bounds.contains(point.latLng)) {
        final math.Point<double> pixel = crs.latLngToPoint(point.latLng, zoom.toDouble()) - tileOffset;

        final int x = ((pixel.x) ~/ cellSize) + 2 + gridOffset.ceil();
        final int y = ((pixel.y) ~/ cellSize) + 2 + gridOffset.ceil();

        final double alt = point.intensity;
        final double k = alt * v;

        // print('k:$k');

        grid[y] = grid[y]..length = (gridSize / cellSize).ceil() + 2 + gridOffset.ceil();
        DataPoint? cell = grid[y][x];

        if (cell == null) {
          grid[y][x] = DataPoint(pixel.x, pixel.y, k);
          cell = grid[y][x];
        } else {
          cell.merge(pixel.x, pixel.y, k);
        }

        if (bounds.contains(point.latLng)) {
          filteredData.add(DataPoint(pixel.x, pixel.y, k));
        }
      }
    }

    return filteredData;
  }

  /// extract bounds from tile coordinates. An optional [buffer] can be passed to expand the bounds
  /// to include a buffer. eg. a buffer of 0.5 would add a half tile buffer to all sides of the bounds.
  LatLngBounds _bounds(TileCoordinates coords, [double buffer = 0]) {
    final LatLng sw = LatLng(tile2Lat(coords.y + 1 + buffer, coords.z), tile2Lon(coords.x - buffer, coords.z));
    final LatLng ne = LatLng(tile2Lat(coords.y - buffer, coords.z), tile2Lon(coords.x + 1 + buffer, coords.z));
    return LatLngBounds(sw, ne);
  }

  /// converts tile y to latitude. if the latitude is out of range it is adjusted to the min/max
  /// latitude (-90,90)
  double tile2Lat(num y, num z) {
    final num yBounded = math.max(y, 0);
    final num n = math.pow(2.0, z);
    final double latRad = math.atan(_sinh(math.pi * (1 - 2 * yBounded / n)));
    final double latDeg = latRad * 180 / math.pi;
    //keep the point in the world
    return latDeg > 0 ? math.min(latDeg, 90).toDouble() : math.max(latDeg, -90).toDouble();
  }

  /// converts the tile x to longitude. if the longitude is out of range then it is adjusted to the
  /// min/max longitude (-180/180)
  double tile2Lon(num x, num z) {
    final num xBounded = math.max(x, 0);
    final double lonDeg = xBounded / math.pow(2.0, z) * 360 - 180;
    return lonDeg > 0 ? math.min(lonDeg, 180).toDouble() : math.max(lonDeg, -180).toDouble();
  }
}

class HeatMapImage extends ImageProvider<HeatMapImage> {
  HeatMapImage(this.data, HeatMapOptions heatmapOptions, double size)
      : generator = HeatMap(heatmapOptions, size, size, data);

  final List<DataPoint> data;
  final HeatMap generator;

  @override
  ImageStreamCompleter loadImage(HeatMapImage key, ImageDecoderCallback decode) {
    return MultiFrameImageStreamCompleter(codec: _generate(), scale: 1);
  }

  Future<ui.Codec> _generate() async {
    final Uint8List bytes = await generator.generate();
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return PaintingBinding.instance.instantiateImageCodecWithSize(buffer);
  }

  @override
  Future<HeatMapImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<HeatMapImage>(this);
  }
}
