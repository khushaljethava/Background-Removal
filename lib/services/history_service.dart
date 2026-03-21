import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// A single history entry representing a processed image.
class HistoryEntry {
  final String id;
  final String originalPath;
  final String resultPath;
  final DateTime processedAt;
  final int processingTimeMs;

  HistoryEntry({
    required this.id,
    required this.originalPath,
    required this.resultPath,
    required this.processedAt,
    this.processingTimeMs = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'originalPath': originalPath,
        'resultPath': resultPath,
        'processedAt': processedAt.toIso8601String(),
        'processingTimeMs': processingTimeMs,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'] as String,
        originalPath: json['originalPath'] as String,
        resultPath: json['resultPath'] as String,
        processedAt: DateTime.parse(json['processedAt'] as String),
        processingTimeMs: json['processingTimeMs'] as int? ?? 0,
      );

  /// Check if the result file still exists on disk.
  bool get resultExists => File(resultPath).existsSync();
}

/// Persistent history of processed images.
/// Saves result PNGs to app documents and metadata to a JSON index.
class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  List<HistoryEntry> _entries = [];
  bool _loaded = false;

  List<HistoryEntry> get entries => List.unmodifiable(_entries);
  int get count => _entries.length;

  Future<Directory> get _historyDir async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/bg_history');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  Future<File> get _indexFile async {
    final dir = await _historyDir;
    return File('${dir.path}/index.json');
  }

  /// Load history from disk. Call once at startup.
  Future<void> load() async {
    if (_loaded) return;
    try {
      final file = await _indexFile;
      if (file.existsSync()) {
        final jsonStr = await file.readAsString();
        final List<dynamic> list = json.decode(jsonStr);
        _entries = list
            .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
            .where((e) => e.resultExists) // prune missing files
            .toList();
        // Sort newest first
        _entries.sort((a, b) => b.processedAt.compareTo(a.processedAt));
      }
    } catch (e) {
      debugPrint('Failed to load history: $e');
      _entries = [];
    }
    _loaded = true;
  }

  Future<void> _save() async {
    try {
      final file = await _indexFile;
      final jsonStr = json.encode(_entries.map((e) => e.toJson()).toList());
      await file.writeAsString(jsonStr);
    } catch (e) {
      debugPrint('Failed to save history: $e');
    }
  }

  /// Save a processed result to history.
  /// Returns the HistoryEntry created.
  Future<HistoryEntry> addResult({
    required String originalPath,
    required Uint8List resultPngBytes,
    int processingTimeMs = 0,
  }) async {
    await load();

    final dir = await _historyDir;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final resultFile = File('${dir.path}/result_$id.png');
    await resultFile.writeAsBytes(resultPngBytes);

    final entry = HistoryEntry(
      id: id,
      originalPath: originalPath,
      resultPath: resultFile.path,
      processedAt: DateTime.now(),
      processingTimeMs: processingTimeMs,
    );

    _entries.insert(0, entry);

    // Keep max 50 entries, delete oldest files
    while (_entries.length > 50) {
      final old = _entries.removeLast();
      try {
        final f = File(old.resultPath);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }

    await _save();
    return entry;
  }

  /// Delete a single entry.
  Future<void> delete(String id) async {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx == -1) return;

    final entry = _entries.removeAt(idx);
    try {
      final f = File(entry.resultPath);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}

    await _save();
  }

  /// Delete all history.
  Future<void> clearAll() async {
    for (final entry in _entries) {
      try {
        final f = File(entry.resultPath);
        if (f.existsSync()) f.deleteSync();
      } catch (_) {}
    }
    _entries.clear();
    await _save();
  }
}
