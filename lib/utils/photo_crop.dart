import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';

/// Crops one food out of a shared photo using a normalized box.
Future<String?> cropIngredientPhoto(String sourcePath, IngredientBox box) async {
  if (!box.usable) return null;
  try {
    final bytes = await File(sourcePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final width = image.width.toDouble();
    final height = image.height.toDouble();

    var left = (box.x * width) - width * 0.03;
    var top = (box.y * height) - height * 0.03;
    var cropW = (box.w * width) + width * 0.06;
    var cropH = (box.h * height) + height * 0.06;
    left = left.clamp(0, width - 1);
    top = top.clamp(0, height - 1);
    cropW = cropW.clamp(1, width - left);
    cropH = cropH.clamp(1, height - top);

    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      image,
      Rect.fromLTWH(left, top, cropW, cropH),
      Rect.fromLTWH(0, 0, cropW, cropH),
      Paint(),
    );
    final cropped = await recorder.endRecording().toImage(
          cropW.round().clamp(1, image.width),
          cropH.round().clamp(1, image.height),
        );
    final data = await cropped.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    cropped.dispose();
    if (data == null) return null;

    final docs = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(docs.path, 'pantry_photos'));
    if (!await folder.exists()) await folder.create(recursive: true);
    final dest = File(
      p.join(folder.path, 'crop_${DateTime.now().microsecondsSinceEpoch}.png'),
    );
    await dest.writeAsBytes(data.buffer.asUint8List(), flush: true);
    return dest.path;
  } catch (_) {
    return null;
  }
}
