import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';

class HeatMapLayer extends StatefulWidget {
  HeatMapLayer(
      {super.key,
      HeatMapOptions? heatMapOptions,
      required this.heatMapDataSource,
      this.reset,
      this.tileDisplay = const TileDisplay.fadeIn(),
      this.maxZoom = 18.0})
      : heatMapOptions = heatMapOptions ?? HeatMapOptions();

  final HeatMapOptions heatMapOptions;
  final HeatMapDataSource heatMapDataSource;
  final Stream<void>? reset;
  final TileDisplay tileDisplay;
  final double maxZoom;

  @override
  State<StatefulWidget> createState() => _HeatMapLayerState();
}

class _HeatMapLayerState extends State<HeatMapLayer> {
  StreamSubscription<void>? _resetSub;

  /// As the reset stream no longer requests the new tile layers, only clears the
  /// cache, a pseudoUrl is generated every time a reset is requested
  late String pseudoUrl;

  @override
  void initState() {
    _regenerateUrl();

    if (widget.reset != null) {
      _resetSub = widget.reset?.listen((_) {
        setState(() {
          _regenerateUrl();
        });
      });
    }
    super.initState();
  }

  @override
  void dispose() {
    _resetSub?.cancel();
    super.dispose();
  }

  void _regenerateUrl() {
    pseudoUrl = DateTime.now().microsecondsSinceEpoch.toString();
  }

  @override
  Widget build(BuildContext context) {
    final MapCamera map = MapCamera.of(context);

    return Opacity(
      opacity: widget.heatMapOptions.layerOpacity,
      child: TileLayer(
        maxZoom: widget.maxZoom,
        urlTemplate: pseudoUrl,
        tileDisplay: widget.tileDisplay,
        tileProvider: HeatMapTilesProvider(
          heatMapOptions: widget.heatMapOptions,
          dataSource: widget.heatMapDataSource,
          crs: map.crs,
        ),
      ),
    );
  }
}
