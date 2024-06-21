// import 'dart:async';
// import 'dart:ui' as ui;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';

// class HeatMapPaint extends StatefulWidget {
//   const HeatMapPaint({Key? key, required this.options, required this.width, required this.height, required this.data})
//       : super(key: key);

//   final HeatMapOptions options;
//   final double width;
//   final double height;
//   final List<DataPoint> data;

//   @override
//   State createState() => _HeatMapPaintState();
// }

// class _HeatMapPaintState extends State<HeatMapPaint> {
//   late ByteData _palette;
//   late ui.Image _baseImage;
//   late Uint8List _heatmap;
//   final Completer<void> ready = Completer<void>();

//   Future<void> get onReady => ready.future;

//   @override
//   void initState() {
//     super.initState();

//     _initHeatmap();
//   }

//   Future<ByteData?> _initColorPalette() async {
//     final List<double> stops = <double>[];
//     final List<Color> colors = <ui.Color>[];

//     for (final MapEntry<double, ui.Color> entry in widget.options.gradient.entries) {
//       colors.add(entry.value);
//       stops.add(entry.key);
//     }
//     final Gradient colorGradient = LinearGradient(colors: colors, stops: stops);
//     const ui.Rect pallateRect = Rect.fromLTRB(0, 0, 256, 1);
//     final ui.Shader shader = colorGradient.createShader(pallateRect, textDirection: TextDirection.ltr);
//     final ui.PictureRecorder recorder = ui.PictureRecorder();
//     final ui.Canvas canvas = Canvas(recorder, pallateRect);
//     final Paint palettePaint = Paint()..shader = shader;
//     canvas.drawRect(pallateRect, palettePaint);
//     final ui.Picture picture = recorder.endRecording();
//     final ui.Image image = await picture.toImage(256, 1);
//     return image.toByteData();
//   }

//   // initialize the palette and image
//   Future<void> _initHeatmap() async {
//     final ByteData? colorPalette = await _initColorPalette();
//     const double radius = 0;

//     final ui.PictureRecorder recorder = ui.PictureRecorder();
//     final ui.Canvas canvas = Canvas(recorder);
//     const AltBaseCirclePainter baseCirclePainter = AltBaseCirclePainter(radius: radius);
//     baseCirclePainter.paint(canvas, Size.zero);
//     final ui.Picture picture = recorder.endRecording();
//     final ui.Image image = await picture.toImage(radius.round() * 2, radius.round() * 2);

//     setState(() {
//       _palette = colorPalette!;
//       _baseImage = image;
//       ready.complete();
//     });
//   }

//   Future<void> _colorize(ui.Image baseCircle) async {
//     if (ready.isCompleted) {
//       final ui.PictureRecorder recorder = ui.PictureRecorder();
//       final ui.Canvas canvas = Canvas(recorder);
//       final GrayScaleHeatMapPainter painter =
//           GrayScaleHeatMapPainter(getBaseCircle: (_) async => baseCircle, data: widget.data);

//       await painter.ready();
//       painter.paint(canvas, Size(widget.width, widget.height));
//       final ui.Image image = await recorder.endRecording().toImage(widget.width.toInt(), widget.height.toInt());
//       final ByteData? byteData = await image.toByteData();

//       for (int i = 0, len = byteData!.lengthInBytes, j = 0; i < len; i += 4) {
//         j = byteData.getUint8(i + 3) * 4;
//         if (i < 40) {}
//         if (j > 0) {
//           byteData.setUint8(i, _palette.getUint8(j));
//           byteData.setUint8(i + 1, _palette.getUint8(j + 1));
//           byteData.setUint8(i + 2, _palette.getUint8(j + 2));
//           byteData.setUint8(i + 3, byteData.getUint8(i + 3) + 255);
//         }
//         if (i < 40) {}
//       }

//       final Uint8List headered =
//           Bitmap.fromHeadless(image.width, image.height, byteData.buffer.asUint8List()).buildHeaded();

//       setState(() {
//         _heatmap = headered;
//       });
//     }
//   }

//   @override
//   void didUpdateWidget(HeatMapPaint oldWidget) {
//     _colorize(_baseImage);
//     super.didUpdateWidget(oldWidget);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: <Widget>[Positioned(top: 0, left: 0, child: Image.memory(_heatmap))],
//     );
//   }
// }

// class HeatMapPainter extends CustomPainter {
//   const HeatMapPainter(this.heatMapImage);

//   final ui.Image heatMapImage;

//   @override
//   void paint(Canvas canvas, Size size) {
//     final ui.Paint paint = Paint();
//     canvas.drawImage(heatMapImage, Offset.zero, paint);
//   }

//   @override
//   bool shouldRepaint(HeatMapPainter oldDelegate) {
//     return true;
//   }
// }

// class HeatMapState {
//   HeatMapState(this.options) {
//     imageSink = StreamController<ui.Image>.broadcast();
//   }

//   final HeatMapOptions options;

//   StreamController<ui.Image>? imageSink;

//   void dispose() {
//     imageSink?.close();
//   }
// }
