import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MemberPhotoCache {
  static const _kBytesPrefix = 'cpva_photo_bytes_v1_';
  static const _maxConcurrent = 2;
  static const _staggerMs = 250;
  static const _maxRetries = 4;
  static const _retryBaseMs = 800;

  final Map<String, Uint8List> _memory = {};
  final Set<String> _inflight = {};
  int _active = 0;
  final List<_Queued> _queue = [];

  Future<Uint8List?> get(String memberId, String? url) async {
    if (memberId.isEmpty || url == null || url.isEmpty) return null;

    final cached = _memory[memberId];
    if (cached != null) return cached;

    final stored = await _readFromDisk(memberId);
    if (stored != null) {
      _memory[memberId] = stored;
      return stored;
    }

    return _enqueue(memberId, url);
  }

  Future<Uint8List?> _enqueue(String memberId, String url) {
    final completer = Completer<Uint8List?>();
    if (_inflight.contains(memberId)) {
      _queue.add(_Queued(memberId, url, completer));
      return completer.future;
    }
    _inflight.add(memberId);
    _queue.add(_Queued(memberId, url, completer));
    _pump();
    return completer.future;
  }

  void _pump() async {
    while (_active < _maxConcurrent && _queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      _active++;
      () async {
        try {
          final bytes = await _fetchWithRetry(next.url);
          if (bytes != null) {
            _memory[next.memberId] = bytes;
            await _writeToDisk(next.memberId, bytes);
          }
          next.completer.complete(bytes);
        } catch (e) {
          next.completer.complete(null);
        } finally {
          _inflight.remove(next.memberId);
          _active--;
          await Future.delayed(const Duration(milliseconds: _staggerMs));
          _pump();
        }
      }();
    }
  }

  Future<Uint8List?> _fetchWithRetry(String url) async {
    int attempt = 0;
    while (attempt < _maxRetries) {
      try {
        final resp =
            await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
          return resp.bodyBytes;
        }
        if (resp.statusCode == 429) {
          attempt++;
          final wait = _retryBaseMs * (1 << (attempt - 1));
          await Future.delayed(Duration(milliseconds: wait));
          continue;
        }
        return null;
      } catch (e) {
        attempt++;
        if (attempt >= _maxRetries) return null;
        await Future.delayed(
          Duration(milliseconds: _retryBaseMs * (1 << (attempt - 1))),
        );
      }
    }
    return null;
  }

  Future<Uint8List?> _readFromDisk(String memberId) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final b64 = prefs.getString('$_kBytesPrefix$memberId');
      if (b64 == null || b64.isEmpty) return null;
      try {
        return base64Decode(b64);
      } catch (_) {
        return null;
      }
    } else {
      try {
        final docs = await getApplicationDocumentsDirectory();
        final f = File('${docs.path}/photo_$memberId.bin');
        if (!await f.exists()) return null;
        return f.readAsBytes();
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> _writeToDisk(String memberId, Uint8List bytes) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final b64 = base64Encode(bytes);
      await prefs.setString('$_kBytesPrefix$memberId', b64);
    } else {
      try {
        final docs = await getApplicationDocumentsDirectory();
        final f = File('${docs.path}/photo_$memberId.bin');
        await f.writeAsBytes(bytes, flush: true);
      } catch (_) {}
    }
  }

  Future<void> clear() async {
    _memory.clear();
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith(_kBytesPrefix));
      for (final k in keys) {
        await prefs.remove(k);
      }
    } else {
      try {
        final docs = await getApplicationDocumentsDirectory();
        final dir = Directory(docs.path);
        final files = dir.listSync().where((e) {
          final name = e.uri.pathSegments.isNotEmpty
              ? e.uri.pathSegments.last
              : '';
          return name.startsWith('photo_') && name.endsWith('.bin');
        });
        for (final f in files) {
          try {
            await f.delete();
          } catch (_) {}
        }
      } catch (_) {}
    }
  }
}

class _Queued {
  final String memberId;
  final String url;
  final Completer<Uint8List?> completer;
  _Queued(this.memberId, this.url, this.completer);
}
