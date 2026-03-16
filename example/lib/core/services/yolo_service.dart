import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class YoloDetection {
  final List<double> rect;
  final double confidence;
  final int classId;
  final Uint8List? mask;

  YoloDetection({
    required this.rect,
    required this.confidence,
    required this.classId,
    this.mask,
  });
}

class YoloService {
  Interpreter? _detectorInterpreter;
  Interpreter? _segmentorInterpreter;

  final int _inputSize = 640;
  final double _confThreshold = 0.25;
  final double _iouThreshold = 0.45;

  double _scale = 1.0;
  int _padX = 0;
  int _padY = 0;

  Future<void> loadModels() async {
    try {
      _detectorInterpreter = await Interpreter.fromAsset(
        'assets/models/follicle_detector.tflite',
        options: InterpreterOptions(), // ..addDelegate(GpuDelegateV2()),
      );
  
      _segmentorInterpreter = await Interpreter.fromAsset(
        'assets/models/hair_segmentor.tflite',
        options: InterpreterOptions(), // ..addDelegate(GpuDelegateV2()),
      );
    } catch (e) {
      rethrow;
    }
  }

  (Float32List, img.Image) _preprocessImage(Uint8List imageBytes) {
    final originalImage = img.decodeImage(imageBytes)!;
    final int origWidth = originalImage.width;
    final int origHeight = originalImage.height;

    _scale = min(_inputSize / origWidth, _inputSize / origHeight);
    final int newWidth = (_scale * origWidth).round();
    final int newHeight = (_scale * origHeight).round();

    final resized = img.copyResize(
      originalImage,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );

    final letterboxed = img.Image(_inputSize, _inputSize);
    letterboxed.fill(0);

    _padX = (_inputSize - newWidth) ~/ 2;
    _padY = (_inputSize - newHeight) ~/ 2;

    img.drawImage(letterboxed, resized, dstX: _padX, dstY: _padY);

    final buffer = Float32List(1 * _inputSize * _inputSize * 3);
    int pixelIndex = 0;

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = letterboxed.getPixel(x, y);
        buffer[pixelIndex++] = img.getRed(pixel) / 255.0;
        buffer[pixelIndex++] = img.getGreen(pixel) / 255.0;
        buffer[pixelIndex++] = img.getBlue(pixel) / 255.0;
      }
    }
    return (buffer, originalImage);
  }

  Future<List<YoloDetection>> detect(String imagePath) async {
    if (_detectorInterpreter == null) throw Exception("Detector not loaded");

    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final (input, originalImage) = _preprocessImage(imageBytes);

    final inputTensor = CustomReshape(
      input,
    ).reshape([1, _inputSize, _inputSize, 3]);

    final outputShape = _detectorInterpreter!.getOutputTensor(0).shape;

    final output = CustomReshape(
      List.filled(outputShape.reduce((a, b) => a * b), 0.0),
    ).reshape(outputShape);

    _detectorInterpreter!.run(inputTensor, output);

    final List<List<double>> typedOutput = (output[0] as List)
        .map((e) => (e as List).cast<double>())
        .toList();

    final detections = _postProcessDetections(
      typedOutput.transpose(),
      originalImage.height,
      originalImage.width,
    );

    return detections;
  }

  Future<List<YoloDetection>> segment(String imagePath) async {
    if (_segmentorInterpreter == null) throw Exception("Segmentor not loaded");

    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final (input, originalImage) = _preprocessImage(imageBytes);

    final inputTensor = CustomReshape(
      input,
    ).reshape([1, _inputSize, _inputSize, 3]);

    final detectionShape = _segmentorInterpreter!.getOutputTensor(0).shape;
    final maskShape = _segmentorInterpreter!.getOutputTensor(1).shape;

    final outputDetections = CustomReshape(
      List.filled(detectionShape.reduce((a, b) => a * b), 0.0),
    ).reshape(detectionShape);

    final outputMasks = CustomReshape(
      List.filled(maskShape.reduce((a, b) => a * b), 0.0),
    ).reshape(maskShape);

    _segmentorInterpreter!.runForMultipleInputs(
      [inputTensor],
      {0: outputDetections, 1: outputMasks},
    );

    final List<List<double>> typedDetections = (outputDetections[0] as List)
        .map((e) => (e as List).cast<double>())
        .toList();

    final List<List<List<double>>> typedMasks = (outputMasks[0] as List)
        .map((e) => (e as List).map((f) => (f as List).cast<double>()).toList())
        .toList();

    return _postProcessSegmentation(
      typedDetections.transpose(), // [8400, 37]
      typedMasks, // [160, 160, 32]
      originalImage.height,
      originalImage.width,
    );
  }

  List<YoloDetection> _postProcessDetections(
    List<List<double>> output,
    int originalImageHeight,
    int originalImageWidth,
  ) {
    final List<YoloDetection> detections = [];

    for (int i = 0; i < output.length; i++) {
      final detection = output[i];
      final confidence = detection[4];

      if (i < 5) {
        print("DEBUG: Detection $i: conf=${confidence.toStringAsFixed(3)}");
      }

      if (confidence > _confThreshold) {
        final xCenter = detection[0] * _inputSize;
        final yCenter = detection[1] * _inputSize;
        final w = detection[2] * _inputSize;
        final h = detection[3] * _inputSize;

        final x1Input = xCenter - w / 2;
        final y1Input = yCenter - h / 2;
        final x2Input = xCenter + w / 2;
        final y2Input = yCenter + h / 2;

        final x1 = (x1Input - _padX) / _scale;
        final y1 = (y1Input - _padY) / _scale;
        final x2 = (x2Input - _padX) / _scale;
        final y2 = (y2Input - _padY) / _scale;

        detections.add(
          YoloDetection(
            rect: [x1, y1, x2, y2],
            confidence: confidence,
            classId: 0,
          ),
        );
      }
    }

    return _applyNMS(detections);
  }

  List<YoloDetection> _postProcessSegmentation(
    List<List<double>> detectionOutput, // [8400, 37]
    List<List<List<double>>> maskPrototypes, // [160, 160, 32]
    int originalImageHeight,
    int originalImageWidth,
  ) {
    final List<YoloDetection> detections = [];

    for (final detection in detectionOutput) {
      final confidence = detection[4];
      if (confidence > _confThreshold) {
        final xCenter = detection[0] * _inputSize;
        final yCenter = detection[1] * _inputSize;
        final w = detection[2] * _inputSize;
        final h = detection[3] * _inputSize;

        final x1Input = xCenter - w / 2;
        final y1Input = yCenter - h / 2;
        final x2Input = xCenter + w / 2;
        final y2Input = yCenter + h / 2;

        final x1 = (x1Input - _padX) / _scale;
        final y1 = (y1Input - _padY) / _scale;
        final x2 = (x2Input - _padX) / _scale;
        final y2 = (y2Input - _padY) / _scale;
        final box = [x1, y1, x2, y2];

        final maskCoefficients = detection.sublist(
          5,
          min(37, detection.length),
        ); // [32]

        final mask = _generateMask(
          maskCoefficients,
          maskPrototypes,
          originalImageWidth,
          originalImageHeight,
          box,
        );

        detections.add(
          YoloDetection(
            rect: box,
            confidence: confidence,
            classId: 0,
            mask: mask,
          ),
        );
      }
    }

    return _applyNMS(detections);
  }

  Uint8List _generateMask(
    List<double> coefficients, // [32]
    List<List<List<double>>> prototypes, // [160, 160, 32]
    int targetWidth,
    int targetHeight,
    List<double> box,
  ) {
    final int protoHeight = prototypes.length; // 160
    final int protoWidth = prototypes[0].length; // 160
    final int numCoefficients = coefficients.length; // 32

    // 1. Create the [160, 160] mask data
    final maskData = List.generate(
      protoHeight,
      (y) => List.generate(protoWidth, (x) => 0.0),
    );

    // 2. Matrix multiplication for channels-last: [160, 160, 32] @ [32]
    for (int y = 0; y < protoHeight; y++) {
      for (int x = 0; x < protoWidth; x++) {
        double sum = 0.0;
        for (int c = 0; c < numCoefficients; c++) {
          sum += prototypes[y][x][c] * coefficients[c];
        }
        maskData[y][x] = sum;
      }
    }

    // 3. Apply sigmoid and create 160x160 prototype image
    final protoImage = img.Image(protoWidth, protoHeight);
    for (int y = 0; y < protoHeight; y++) {
      for (int x = 0; x < protoWidth; x++) {
        final sigmoid = 1 / (1 + exp(-maskData[y][x]));
        final value = (sigmoid > 0.5 ? 255 : 0).toInt();
        protoImage.setPixel(x, y, img.getColor(value, value, value));
      }
    }

    // --- START FINAL FIX ---
    // 4. Scale 160x160 prototype mask to 640x640
    final scaledProtoMask = img.copyResize(
      protoImage,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.nearest, // <-- THIS IS THE FIX
    );
    // --- END FINAL FIX ---

    // 5. Create final mask at original image size (all black)
    final finalMaskImage = img.Image(targetWidth, targetHeight);

    // 6. Iterate over the bounding box in the *original image*
    final int x1 = box[0].floor();
    final int y1 = box[1].floor();
    final int x2 = box[2].ceil();
    final int y2 = box[3].ceil();

    for (int y = y1; y < y2; y++) {
      for (int x = x1; x < x2; x++) {
        // Skip pixels outside the image bounds
        if (x < 0 || x >= targetWidth || y < 0 || y >= targetHeight) continue;

        // 7. Map (x, y) back to the 640x640 letterboxed space
        final int px = (x * _scale + _padX).round();
        final int py = (y * _scale + _padY).round();

        // Skip pixels outside the 640x640 bounds
        if (px < 0 || px >= _inputSize || py < 0 || py >= _inputSize) continue;

        // 8. Sample the 640x640 mask
        final double pixelValue = img
            .getRed(scaledProtoMask.getPixel(px, py))
            .toDouble();

        // 9. If the pixel is "on", draw it on the final mask
        if (pixelValue > 127) {
          finalMaskImage.setPixel(x, y, img.getColor(255, 255, 255));
        }
      }
    }

    // 10. Encode the final, full-size mask as a PNG
    return Uint8List.fromList(img.encodePng(finalMaskImage));
  }

  List<YoloDetection> _applyNMS(List<YoloDetection> detections) {
    if (detections.isEmpty) return [];

    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    final List<YoloDetection> result = [];
    final List<bool> suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      result.add(detections[i]);
      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;
        final iou = _calculateIoU(detections[i].rect, detections[j].rect);
        if (iou > _iouThreshold) {
          suppressed[j] = true;
        }
      }
    }
    return result;
  }

  double _calculateIoU(List<double> box1, List<double> box2) {
    final x1 = max(box1[0], box2[0]);
    final y1 = max(box1[1], box2[1]);
    final x2 = min(box1[2], box2[2]);
    final y2 = min(box1[3], box2[3]);
    final intersection = max(0.0, x2 - x1) * max(0.0, y2 - y1);
    final area1 = (box1[2] - box1[0]) * (box1[3] - box1[1]);
    final area2 = (box2[2] - box2[0]) * (box2[3] - box2[1]);
    final union = area1 + area2 - intersection;
    return union > 0 ? intersection / union : 0;
  }

  void dispose() {
    _detectorInterpreter?.close();
    _segmentorInterpreter?.close();
  }
}

extension Transpose on List<List<double>> {
  List<List<double>> transpose() {
    if (isEmpty) return [];
    return List.generate(
      this[0].length,
      (i) => List.generate(length, (j) => this[j][i]),
    );
  }
}

// ignore: strict_raw_type
extension CustomReshape on List {
  List<dynamic> reshape(List<int> shape) {
    if (shape.isEmpty) return [];
    int totalElements = 1;
    for (int dim in shape) {
      totalElements *= dim;
    }
    if (length != totalElements) {
      throw ArgumentError(
        'Total elements in list ($length) does not match shape ($totalElements)',
      );
    }
    dynamic build(int dim, Iterator<dynamic> iter) {
      if (dim == shape.length - 1) {
        return List.generate(
          shape[dim],
          (_) => iter.moveNext() ? iter.current : null,
        );
      }
      return List.generate(shape[dim], (_) => build(dim + 1, iter));
    }

    return build(0, iterator) as List<dynamic>;
  }
}
