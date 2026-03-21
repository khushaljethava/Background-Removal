import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Service responsible for image preprocessing (before inference)
/// and postprocessing (applying mask to create transparent PNG).
class ImageProcessingService {
  /// The model expects 1024×1024 input
  static const int modelInputSize = 1024;

  /// ImageNet normalization constants
  static const List<double> mean = [0.485, 0.456, 0.406];
  static const List<double> std = [0.229, 0.224, 0.225];

  /// Loads an image from file and returns the decoded Image object.
  /// [maxDimension] caps the longest side (for faster processing / less memory).
  static Future<img.Image> loadImage(File file,
      {int? maxDimension}) async {
    final bytes = await file.readAsBytes();
    return await compute(
        _decodeAndOptionallyResize, _DecodeParams(bytes, maxDimension));
  }

  static img.Image _decodeImage(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Failed to decode image');
    return decoded;
  }

  static img.Image _decodeAndOptionallyResize(_DecodeParams params) {
    final decoded = img.decodeImage(params.bytes);
    if (decoded == null) throw Exception('Failed to decode image');
    if (params.maxDimension == null) return decoded;
    final m = params.maxDimension!;
    final w = decoded.width;
    final h = decoded.height;
    if (w <= m && h <= m) return decoded;
    if (w >= h) {
      return img.copyResize(decoded, width: m, height: (h * m / w).round(),
          interpolation: img.Interpolation.linear);
    }
    return img.copyResize(decoded, width: (w * m / h).round(), height: m,
        interpolation: img.Interpolation.linear);
  }

  /// Preprocesses an image for BEN2-ONNX inference:
  /// 1. Resize to 1024×1024
  /// 2. Normalize with ImageNet mean/std
  /// 3. Convert to CHW Float32 format [1, 3, 1024, 1024]
  static Future<Float32List> preprocessImage(img.Image image) async {
    return await compute(_preprocessInIsolate, image);
  }

  static Float32List _preprocessInIsolate(img.Image image) {
    // Resize to model input size using Lanczos interpolation for quality
    final resized = img.copyResize(
      image,
      width: modelInputSize,
      height: modelInputSize,
      interpolation: img.Interpolation.linear,
    );

    // Create CHW float32 tensor: [1, 3, 1024, 1024]
    final int channels = 3;
    final int pixelCount = modelInputSize * modelInputSize;
    final tensorData = Float32List(channels * pixelCount);

    for (int y = 0; y < modelInputSize; y++) {
      for (int x = 0; x < modelInputSize; x++) {
        final pixel = resized.getPixel(x, y);
        final idx = y * modelInputSize + x;

        // Rescale only: pixel / 255.0
        // Channel order: R, G, B (CHW layout)
        tensorData[0 * pixelCount + idx] = pixel.r.toDouble() / 255.0;
        tensorData[1 * pixelCount + idx] = pixel.g.toDouble() / 255.0;
        tensorData[2 * pixelCount + idx] = pixel.b.toDouble() / 255.0;
      }
    }

    return tensorData;
  }

  /// Postprocesses the model output mask and applies it to the original image
  /// to create a transparent PNG. Optional [edgeFeatherRadius] softens mask edges.
  static Future<Uint8List> postprocessMask({
    required img.Image originalImage,
    required Float32List maskData,
    int edgeFeatherRadius = 0,
  }) async {
    return await compute(
      _postprocessInIsolate,
      _PostprocessParams(originalImage, maskData, edgeFeatherRadius),
    );
  }

  static Uint8List _postprocessInIsolate(_PostprocessParams params) {
    final originalImage = params.image;
    Float32List mask = params.maskData;
    final int maskSize = modelInputSize;
    final int origW = originalImage.width;
    final int origH = originalImage.height;

    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;
    for (int i = 0; i < mask.length; i++) {
      if (mask[i] < minVal) minVal = mask[i];
      if (mask[i] > maxVal) maxVal = mask[i];
    }
    final range = maxVal - minVal;
    final normalizedMask = Float32List(mask.length);
    for (int i = 0; i < mask.length; i++) {
      normalizedMask[i] =
          range > 0 ? ((mask[i] - minVal) / range) : 0.0;
    }

    if (params.edgeFeatherRadius > 0) {
      _featherMask(normalizedMask, maskSize, params.edgeFeatherRadius);
    }

    final resultImage = img.Image(width: origW, height: origH, numChannels: 4);
    final double scaleX = maskSize / origW;
    final double scaleY = maskSize / origH;

    for (int y = 0; y < origH; y++) {
      final int maskY = (y * scaleY).floor().clamp(0, maskSize - 1);
      final int rowOffset = maskY * maskSize;
      for (int x = 0; x < origW; x++) {
        final int maskX = (x * scaleX).floor().clamp(0, maskSize - 1);
        final double alphaVal = normalizedMask[rowOffset + maskX];
        final origPixel = originalImage.getPixel(x, y);
        resultImage.setPixelRgba(
          x,
          y,
          origPixel.r.toInt(),
          origPixel.g.toInt(),
          origPixel.b.toInt(),
          (alphaVal * 255).clamp(0, 255).toInt(),
        );
      }
    }
    return Uint8List.fromList(img.encodePng(resultImage));
  }

  static void _featherMask(Float32List mask, int size, int radius) {
    if (radius <= 0) return;
    final tmp = Float32List(mask.length);
    for (int r = 0; r < radius; r++) {
      for (int y = 0; y < size; y++) {
        for (int x = 0; x < size; x++) {
          double sum = 0;
          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              final nx = (x + dx).clamp(0, size - 1);
              final ny = (y + dy).clamp(0, size - 1);
              sum += mask[ny * size + nx];
            }
          }
          tmp[y * size + x] = sum / 9;
        }
      }
      mask.setRange(0, mask.length, tmp);
    }
  }

  /// Composites a transparent PNG foreground onto a background image.
  /// Both are resized so foreground size matches; background is crop-centered.
  static Future<Uint8List> compositeForegroundOnImage({
    required Uint8List foregroundPngBytes,
    required Uint8List backgroundImageBytes,
  }) async {
    return await compute(
      _compositeForegroundOnImageIsolate,
      _CompositeImageParams(foregroundPngBytes, backgroundImageBytes),
    );
  }

  static Uint8List _compositeForegroundOnImageIsolate(
      _CompositeImageParams params) {
    final fg = img.decodePng(params.foregroundPngBytes);
    final bg = img.decodeImage(params.backgroundImageBytes);
    if (fg == null || bg == null) {
      return params.foregroundPngBytes;
    }
    final fgW = fg.width;
    final fgH = fg.height;
    img.Image bgResized;
    if (bg.width >= fgW && bg.height >= fgH) {
      final x = (bg.width - fgW) ~/ 2;
      final y = (bg.height - fgH) ~/ 2;
      bgResized = img.copyCrop(bg, x: x, y: y, width: fgW, height: fgH);
    } else {
      bgResized = img.copyResize(bg, width: fgW, height: fgH);
    }
    final result = img.compositeImage(bgResized, fg);
    return Uint8List.fromList(img.encodePng(result));
  }

  /// Creates a side-by-side comparison image (original vs result).
  static Future<Uint8List> createComparison({
    required img.Image originalImage,
    required Uint8List resultPngBytes,
  }) async {
    return await compute(
      _createComparisonInIsolate,
      _ComparisonParams(originalImage, resultPngBytes),
    );
  }

  static Uint8List _createComparisonInIsolate(_ComparisonParams params) {
    final resultImage = img.decodePng(params.resultPngBytes)!;
    final origW = params.image.width;
    final origH = params.image.height;

    // Create a canvas with both images side by side
    final canvas = img.Image(width: origW * 2, height: origH);

    // Draw original on the left
    img.compositeImage(canvas, params.image, dstX: 0, dstY: 0);
    // Draw result on the right
    img.compositeImage(canvas, resultImage, dstX: origW, dstY: 0);

    return Uint8List.fromList(img.encodePng(canvas));
  }
}

class _DecodeParams {
  final Uint8List bytes;
  final int? maxDimension;
  _DecodeParams(this.bytes, this.maxDimension);
}

class _PostprocessParams {
  final img.Image image;
  final Float32List maskData;
  final int edgeFeatherRadius;
  const _PostprocessParams(this.image, this.maskData, this.edgeFeatherRadius);
}

class _CompositeImageParams {
  final Uint8List foregroundPngBytes;
  final Uint8List backgroundImageBytes;
  _CompositeImageParams(this.foregroundPngBytes, this.backgroundImageBytes);
}

/// Parameters container for isolate comparison creation
class _ComparisonParams {
  final img.Image image;
  final Uint8List resultPngBytes;
  const _ComparisonParams(this.image, this.resultPngBytes);
}
