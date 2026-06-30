import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:human_checksum/human_checksum.dart';

/// A simple LRU cache with a maximum capacity.
/// 
/// When the cache exceeds [maxSize], the least recently accessed entries
/// are evicted to make room for new entries.
class _LruCache<K, V> {
  final int maxSize;
  // LinkedHashMap is required for insertion-order iteration (LRU eviction).
  // ignore: prefer_collection_literals
  final _cache = LinkedHashMap<K, V>();
  
  _LruCache(this.maxSize) : assert(maxSize > 0);
  
  V? get(K key) {
    final value = _cache.remove(key);
    if (value != null) {
      // Re-insert to mark as recently used
      _cache[key] = value;
    }
    return value;
  }
  
  void put(K key, V value) {
    // Remove if exists to update access order
    _cache.remove(key);
    _cache[key] = value;
    
    // Evict oldest entries if over capacity
    while (_cache.length > maxSize) {
      _cache.remove(_cache.keys.first);
    }
  }
  
  bool containsKey(K key) => _cache.containsKey(key);
  
  void clear() => _cache.clear();
  
  int get length => _cache.length;
}

class HumanReadableChecksumService {
  static final HumanReadableChecksumService _instance = HumanReadableChecksumService._internal();
  factory HumanReadableChecksumService() => _instance;
  HumanReadableChecksumService._internal();

  /// Maximum length for an SS58 address string.
  /// SS58 addresses are typically 47-50 characters. We allow some margin
  /// but reject obviously oversized strings to prevent memory abuse.
  static const int maxAddressLength = 64;
  
  /// Maximum number of cached checksum results.
  /// This bounds memory usage from untrusted address inputs.
  static const int maxCacheSize = 1000;

  List<String>? _cachedWordList;
  Isolate? _isolate;
  SendPort? _isolateSendPort;
  final _checkPhraseCache = _LruCache<String, String>(maxCacheSize);
  Completer<void>? _isolateReadyCompleter;

  Future<void> initialize() async {
    if (_cachedWordList != null && _isolateSendPort != null && (_isolateReadyCompleter?.isCompleted ?? false)) {
      return;
    }

    if (_isolateReadyCompleter != null && !_isolateReadyCompleter!.isCompleted) {
      await _isolateReadyCompleter!.future;
      return;
    }

    _isolateReadyCompleter = Completer<void>();

    try {
      if (_cachedWordList == null) {
        final wordList = await rootBundle.loadString('assets/text/human_checkphrase_final_wordlist.txt');
        _cachedWordList = wordList.split('\n').where((word) => word.isNotEmpty).toList();

        if (_cachedWordList!.length != 2048) {
          _isolateReadyCompleter!.completeError(Exception('Word list must contain exactly 2048 words'));
          throw Exception('Word list must contain exactly 2048 words');
        }
      }

      if (_isolateSendPort == null) {
        final receivePort = ReceivePort();
        _isolate = await Isolate.spawn(_isolateEntry, [receivePort.sendPort, _cachedWordList!]);
        _isolateSendPort = await receivePort.first as SendPort;
      }

      _isolateReadyCompleter!.complete();
    } catch (e, s) {
      debugPrint('Error during checksum isolate initialization: $e');
      debugPrint('Initialization error stack: $s');
      if (!(_isolateReadyCompleter?.isCompleted ?? false)) {
        _isolateReadyCompleter!.completeError(e);
      }
      _isolate?.kill();
      _isolate = null;
      _isolateSendPort = null;
      _cachedWordList = null;
      rethrow;
    }
  }

  Future<String> getHumanReadableName(String address, {upperCase = true}) async {
    // Validate address length to prevent memory abuse from oversized strings.
    // SS58 addresses are typically 47-50 characters.
    if (address.isEmpty || address.length > maxAddressLength) {
      return '';
    }
    
    try {
      final key = address + (upperCase ? '#U' : '');
      final cached = _checkPhraseCache.get(key);
      if (cached != null) {
        return cached;
      }

      if (!(_isolateReadyCompleter?.isCompleted ?? false)) {
        await initialize();
      }

      if (_isolateSendPort == null) {
        debugPrint('Error: _isolateSendPort is null after successful initialization wait.');
        return '';
      }

      final responsePort = ReceivePort();
      _isolateSendPort!.send([address, responsePort.sendPort]);
      final result = await responsePort.first as String?;
      responsePort.close();

      var finalResult = result ?? '';

      if (upperCase && finalResult.isNotEmpty) {
        finalResult = finalResult
            .split('-')
            .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : word)
            .toList()
            .join('-');
      }
      
      // Only cache non-empty results to avoid caching invalid addresses
      if (finalResult.isNotEmpty) {
        _checkPhraseCache.put(key, finalResult);
      }
      return finalResult;
    } catch (e, s) {
      debugPrint('Error in getHumanReadableName for address $address: $e');
      debugPrint('Lookup error stack: $s');
      return '';
    }
  }

  void dispose() {
    debugPrint('Disposing HumanReadableChecksumService...');
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _isolateSendPort = null;
    _cachedWordList = null;
    _checkPhraseCache.clear();
    if (!(_isolateReadyCompleter?.isCompleted ?? false)) {
      _isolateReadyCompleter?.completeError('HumanReadableChecksumService disposed');
    }
    _isolateReadyCompleter = null;
    debugPrint('HumanReadableChecksumService disposed.');
  }
}

void _isolateEntry(List<dynamic> args) async {
  final mainSendPort = args[0] as SendPort;
  final words = args[1] as List<String>;

  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  await for (final message in receivePort) {
    final address = message[0] as String;
    final replyTo = message[1] as SendPort;

    try {
      final humanChecksum = HumanChecksum(words);
      final result = humanChecksum.addressToChecksum(address).join('-');
      replyTo.send(result);
    } catch (e, s) {
      debugPrint('Error in checksum isolate processing address $address: $e');
      debugPrint('Isolate error stack: $s');
      replyTo.send('');
    }
  }
  debugPrint('Checksum isolate message stream closed.');
}
