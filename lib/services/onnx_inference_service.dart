import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Service responsible for downloading the BEN2-ONNX model,
/// initializing ONNX Runtime, and running background removal inference.
class OnnxInferenceService {
  static final OnnxInferenceService _instance = OnnxInferenceService._internal();
  factory OnnxInferenceService() => _instance;
  OnnxInferenceService._internal();

  static const String _modelFileName = 'ormbg_model.onnx';
  static const String _modelAssetPath = 'assets/models/ormbg_model.onnx';

  // Optional fallback URL (kept for recovery / development), but normal app flow
  // should not need network downloads.
  static const String _modelUrl =
      'https://huggingface.co/onnx-community/ormbg-ONNX/resolve/main/onnx/model.onnx';

  final OnnxRuntime _ort = OnnxRuntime();
  OrtSession? _session;
  bool _isModelReady = false;
  final ValueNotifier<double> downloadProgress = ValueNotifier(0.0);
  Completer<String>? _downloadCompleter;
  int? _bundledModelSizeBytes;

  bool get isModelReady => _isModelReady;

  /// Returns the local file path where the model is cached.
  Future<File> get _modelFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_modelFileName');
  }

  Future<int> _getBundledModelSizeBytes() async {
    if (_bundledModelSizeBytes != null) return _bundledModelSizeBytes!;
    final data = await rootBundle.load(_modelAssetPath);
    _bundledModelSizeBytes = data.lengthInBytes;
    return _bundledModelSizeBytes!;
  }

  Future<File> _ensureModelAvailableLocallyFromAsset() async {
    final file = await _modelFile;
    final int bundledSize;
    try {
      bundledSize = await _getBundledModelSizeBytes();
    } on FlutterError {
      throw Exception(
        'Bundled ONNX model not found at $_modelAssetPath. Add the file to your assets and rebuild the app.',
      );
    }

    if (file.existsSync()) {
      final localSize = await file.length();
      if (localSize == bundledSize && localSize > 0) {
        return file;
      }
      try {
        file.deleteSync();
      } catch (_) {}
    }

    final data = await rootBundle.load(_modelAssetPath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<int?> _fetchRemoteModelSizeBytes() async {
    try {
      final res = await http.head(Uri.parse(_modelUrl));
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final len = res.headers['content-length'];
        if (len == null) return null;
        return int.tryParse(len);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> _isLocalModelValid(File file) async {
    if (!file.existsSync()) return false;
    final length = await file.length();
    if (length <= 0) return false;

    final remoteLength = await _fetchRemoteModelSizeBytes();
    if (remoteLength == null || remoteLength <= 0) {
      return length > 50 * 1024 * 1024;
    }
    return length == remoteLength;
  }

  /// Check if model is already downloaded and cached.
  Future<bool> isModelDownloaded() async {
    final file = await _modelFile;
    if (!file.existsSync()) return false;
    final localSize = await file.length();
    if (localSize <= 0) return false;
    try {
      final bundledSize = await _getBundledModelSizeBytes();
      return localSize == bundledSize;
    } catch (_) {
      return false;
    }
  }

  /// Downloads the BEN2 ONNX model from HuggingFace with progress reporting.
  /// Streams directly to disk to minimize memory usage for the 235MB file.
  Future<String> downloadModel({
    void Function(double progress)? onProgress,
  }) async {
    final file = await _modelFile;

    // If already downloading, wait for it
    if (_downloadCompleter != null) {
      // We still want to report progress to the new caller's callback if provided
      // But the progress is already being updated via the notifier
      return _downloadCompleter!.future;
    }

    if (await _isLocalModelValid(file)) {
      downloadProgress.value = 1.0;
      onProgress?.call(1.0);
      return file.path;
    }

    if (file.existsSync()) {
      try {
        file.deleteSync();
      } catch (_) {}
    }

    _downloadCompleter = Completer<String>();
    try {
      final request = http.Request('GET', Uri.parse(_modelUrl));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download model: HTTP ${response.statusCode}',
        );
      }

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final sink = file.openWrite();

      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0) {
            final p = receivedBytes / totalBytes;
            downloadProgress.value = p;
            onProgress?.call(p);
          }
        }
      } finally {
        await sink.close();
      }

      if (totalBytes > 0) {
        final localSize = await file.length();
        if (localSize != totalBytes) {
          try {
            file.deleteSync();
          } catch (_) {}
          throw Exception('Model download incomplete');
        }
      }

      _downloadCompleter!.complete(file.path);
      return file.path;
    } catch (e) {
      if (file.existsSync()) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
      _downloadCompleter?.completeError(e);
      rethrow;
    } finally {
      _downloadCompleter = null;
    }
  }

  /// Initializes the ONNX Runtime session with the cached model.
  Future<void> initSession() async {
    if (_session != null) return;

    final file = await _ensureModelAvailableLocallyFromAsset();

    // Create session with optimized options supported by the package
    final options = OrtSessionOptions(
      intraOpNumThreads: 1, // Reduce threads to save RAM overhead on mobile
      interOpNumThreads: 1,
      providers: [OrtProvider.CPU],
      useArena: true,
    );

    try {
      _session = await _ort.createSession(file.path, options: options);
    } catch (e) {
      final msg = e.toString();
      final shouldRetry = msg.contains('ORT_INVALID_PROTOBUF') ||
          msg.toLowerCase().contains('invalid protobuf');
      if (shouldRetry) {
        try {
          if (file.existsSync()) file.deleteSync();
        } catch (_) {}

        // Primary recovery path: restore from bundled asset.
        final repaired = await _ensureModelAvailableLocallyFromAsset();
        _session = await _ort.createSession(repaired.path, options: options);
      } else {
        rethrow;
      }
    }
    _isModelReady = true;

    // Log model I/O info for debugging
    final inputInfo = await _session!.getInputInfo();
    final outputInfo = await _session!.getOutputInfo();
    debugPrint('ONNX Model Input: $inputInfo');
    debugPrint('ONNX Model Output: $outputInfo');
  }

  /// Runs inference on a preprocessed image tensor.
  ///
  /// [inputData] is a Float32List of shape [1, 3, 1024, 1024] — a normalized
  /// RGB image in CHW format.
  ///
  /// Returns the output mask as a Float32List of shape [1, 1, 1024, 1024].
  Future<Float32List> runInference(Float32List inputData) async {
    if (_session == null) {
      throw Exception('Session not initialized. Call initSession() first.');
    }

    // Create input tensor with shape [1, 3, 1024, 1024] (batch, channels, h, w)
    final inputTensor = await OrtValue.fromList(
      inputData,
      [1, 3, 1024, 1024],
    );

    // The BEN2 model expects input named 'input'
    final inputName = _session!.inputNames.first;
    final inputs = {inputName: inputTensor};

    // Run the model
    final outputs = await _session!.run(inputs);

    // Extract the output mask more efficiently
    final outputName = _session!.outputNames.first;
    final outputTensor = outputs[outputName]!;
    
    // Get data without multiple intermediate lists if possible
    final outputData = await outputTensor.asFlattenedList();
    
    // Use a loop for conversion instead of .map().toList() to save RAM/GC
    final result = Float32List(outputData.length);
    for (int i = 0; i < outputData.length; i++) {
      result[i] = (outputData[i] as num).toDouble();
    }

    // Cleanup tensors immediately
    await inputTensor.dispose();
    for (final tensor in outputs.values) {
      await tensor.dispose();
    }

    return result;
  }

  /// Releases ONNX Runtime resources.
  Future<void> dispose() async {
    if (_session != null) {
      await _session!.close();
      _session = null;
      _isModelReady = false;
    }
  }
}
