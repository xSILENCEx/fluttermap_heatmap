import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heatmap Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'flutter_mapmap heat_map demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  StreamController<void> _rebuildStream = StreamController.broadcast();
  List<WeightedLatLng> data = [];
  List<Map<double, Color>> get gradients => [
        <double, Color>{
          0.25: Colors.blue,
          0.55: Colors.yellow,
          0.85: Colors.red,
          1.0: Colors.purple,
        },
        HeatMapOptions.defaultGradient,
      ];

  var index = 0;

  @override
  initState() {
    _loadData();
    super.initState();
  }

  @override
  dispose() {
    _rebuildStream.close();
    super.dispose();
  }

  _loadData() async {
    var str = await rootBundle.loadString('assets/initial_data.json');
    List<dynamic> result = jsonDecode(str);

    data = result.map((e) => e as List<dynamic>).map(
      (e) {
        return WeightedLatLng(LatLng(e[0], e[1]), 1, 10);
      },
    ).toList();

    setState(() {});
  }

  void _incrementCounter() {
    setState(() {
      index = index + 1;

      if (index >= gradients.length) {
        index = 0;
      }

      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _rebuildStream.add(null);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final map = new FlutterMap(
      options: new MapOptions(
        initialCenter: new LatLng(57.8827, -6.0400),
        initialZoom: 8.0,
        minZoom: 5,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://mt.google.com/vt/lyrs=m&scale=2&x={x}&y={y}&z={z}&apistyle=${<String>[
            // hideRoadArrow
            's.t%3A3|s.e%3Al.i|p.v%3Aoff',
            // roadingColor
            's.t%3A3|s.e%3Ag|p.c%3A%23ffffffff',
            // roadingLabelColor
            's.t%3A3|s.e%3Al.t.f|p.c%3A%23ff8a8ab1',
            // roadingLabelBorderColor
            's.t%3A3|s.e%3Al.t.s|p.c%3A%23ffffffff',
            // hidePlaceIcon
            's.t%3A2|s.e%3Al.i|p.v%3Aoff',
            // placeColor
            's.t%3A2|s.e%3Ag|p.c%3A%23ffe6e6e6',
            // placeLabelColor
            's.t%3A2|s.e%3Al.t.f|p.c%3A%23ff8a8ab1',
            // hideLocalRoad
            // 's.t%3A51|s.e%3Ag|p.v%3Aoff',
            // landscapeColor
            's.t%3A82|s.e%3Ag.f|p.c%3A%23fff7f7fa',
            // buildingLabelColor
            's.t%3A81|s.e%3Al.t.f|p.c%3A%23ff8a8ab1',
            // waterColor
            's.t%3A6|s.e%3Ag|p.c%3A%23ffc0daf2',
            // waterLabelColor
            's.t%3A6|s.e%3Al.t.f|p.c%3A%23ff6c94b7',
            // administrativeDivisionColor
            's.t%3A1|s.e%3Al.t.f|p.c%3A%23ff686999',
          ].join(',')}",
          userAgentPackageName: 'app',
        ),
        if (data.isNotEmpty)
          HeatMapLayer(
            maxZoom: 18,
            heatMapDataSource: InMemoryHeatMapDataSource(data: data),
            heatMapOptions: HeatMapOptions(
              gradient: this.gradients[this.index],
              // minOpacity: 0.1,
              // blurFactor: 10,
            ),
            reset: _rebuildStream.stream,
          )
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      backgroundColor: Colors.pink,
      body: Center(child: Container(child: map)),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Switch Gradient',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
