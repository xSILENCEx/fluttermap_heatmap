import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'transparent.dart';

class HeatMap {
  HeatMap(this.options, this.width, this.height, this.data) {
    _initColorPalette();
  }

  final HeatMapOptions options;
  final double width;
  final double height;
  final List<DataPoint> data;

  late ByteData _palette;
  final Completer<void> ready = Completer<void>();

  /// Base Shapes used to represent each point
  final Map<double, ui.Image> _baseShapes = <double, ui.Image>{};

  Future<void> get onReady => ready.future;

  /// generates a 256 color palette used to colorize the heatmap
  Future<void> _initColorPalette() async {
    final List<double> stops = <double>[];
    final List<Color> colors = <ui.Color>[];

    for (final MapEntry<double, ui.Color> entry in options.gradient.entries) {
      colors.add(entry.value);
      stops.add(entry.key);
    }

    final Gradient colorGradient = LinearGradient(colors: colors, stops: stops);
    const ui.Rect paletteRect = Rect.fromLTRB(0, 0, 256, 1);

    final ui.Shader shader = colorGradient.createShader(paletteRect, textDirection: TextDirection.ltr);

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = Canvas(recorder, paletteRect);

    final Paint palettePaint = Paint()..shader = shader;
    canvas.drawRect(paletteRect, palettePaint);
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(256, 1);
    _palette = (await image.toByteData())!;
    ready.complete();
  }

  Future<ui.Image> _getBaseShape() async {
    final double radius = options.radius;
    if (_baseShapes.containsKey(radius)) {
      return _baseShapes[radius]!;
    }

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = Canvas(recorder);
    final AltBaseCirclePainter baseCirclePainter = AltBaseCirclePainter(radius: radius, blurFactor: options.blurFactor);
    final Size size = Size.fromRadius(radius);
    baseCirclePainter.paint(canvas, size);
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(radius.round() * 2, radius.round() * 2);

    _baseShapes[radius] = image;
    return image;
  }

  Future<ui.Image> _grayscaleHeatmap(ui.Image baseCircle) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final ui.Canvas canvas = Canvas(recorder);

    final GrayScaleHeatMapPainter painter =
        GrayScaleHeatMapPainter(baseCircle: baseCircle, data: data, minOpacity: options.minOpacity);
    painter.paint(canvas, Size(width + options.radius, height + options.radius));

    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(width.toInt(), height.toInt());
    return image;
  }

  Future<Uint8List> _colorize(ui.Image image) async {
    final ByteData? byteData = await image.toByteData();
    final int? byteCount = byteData?.lengthInBytes;
    int transparentByteCount = 0;
    for (int i = 0, len = byteData!.lengthInBytes, j = 0; i < len; i += 4) {
      j = byteData.getUint8(i + 3) * 4;
      if (i < 40) {}
      if (j > 0) {
        byteData.setUint8(i, _palette.getUint8(j));
        byteData.setUint8(i + 1, _palette.getUint8(j + 1));
        byteData.setUint8(i + 2, _palette.getUint8(j + 2));
        byteData.setUint8(i + 3, byteData.getUint8(i + 3) + 255);
      } else {
        transparentByteCount = transparentByteCount + 4;
      }
      if (i < 40) {}
    }

    Uint8List bitmap;
    // for some reason transparency is not honored when rendering on web. by checking
    // all bytes are transparent we can render a single pixel transparent png instead
    if (transparentByteCount == byteCount) {
      bitmap = kTransparentImage;
    } else {
      bitmap = Bitmap.fromHeadless(image.width, image.height, byteData.buffer.asUint8List()).buildHeaded();
    }

    return bitmap;
  }

  Future<Uint8List> generate() async {
    await ready.future;

    // if there is no data then return a transparent image
    if (data.isEmpty) {
      return kTransparentImage;
    }
    // generate shape to be used for all points on the heatmap
    final ui.Image baseShape = await _getBaseShape();

    final ui.Image grayscale = await _grayscaleHeatmap(baseShape);

    final Uint8List heatmapBytes = await _colorize(grayscale);

    return heatmapBytes;
  }
}
