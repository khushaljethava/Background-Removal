import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Simple in-memory cache for processed image results.
/// Keys are image file paths, values are the processed PNG bytes.
class ResultCache {
  static final ResultCache _instance = ResultCache._internal();
  factory ResultCache() => _instance;
  ResultCache._internal();

  final Map<String, Uint8List> _cache = {};
  final int _maxSize = 10;

  Uint8List? get(String key) => _cache[key];

  void put(String key, Uint8List value) {
    if (_cache.length >= _maxSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  bool contains(String key) => _cache.containsKey(key);
}
