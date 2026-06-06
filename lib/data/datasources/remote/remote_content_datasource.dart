import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'firestore_service.dart';

class RemoteContentDataSource {
  final FirestoreService _firestore;
  final String _collection;
  final String _seedFlagKey;
  final String? _permanentFlagKey;

  RemoteContentDataSource(
    this._firestore,
    this._collection,
    this._seedFlagKey, {
    String? permanentFlagKey,
  }) : _permanentFlagKey = permanentFlagKey;

  Future<void> seedFromJson(String assetName, String listKey) async {
    if (!kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_seedFlagKey, true);
      return;
    }
    if (_permanentFlagKey != null) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_permanentFlagKey!) == true) {
        await prefs.setBool(_seedFlagKey, true);
        return;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seedFlagKey) == true) return;
    final existing = await _firestore.getCollection(_collection);
    if (existing.isNotEmpty) {
      await prefs.setBool(_seedFlagKey, true);
      if (_permanentFlagKey != null) {
        await prefs.setBool(_permanentFlagKey!, true);
      }
      return;
    }
    final raw = await rootBundle.loadString('assets/data/$assetName.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final list = (data[listKey] as List).cast<Map<String, dynamic>>();
    for (final item in list) {
      final id = item['id']?.toString();
      if (id == null || id.isEmpty) {
        await _firestore.addDocument(_collection, item);
      } else {
        await _firestore.setDocument(_collection, id, item);
      }
    }
    await prefs.setBool(_seedFlagKey, true);
    if (_permanentFlagKey != null) {
      await prefs.setBool(_permanentFlagKey!, true);
    }
  }

  Future<void> forceReseedFromJson(String assetName, String listKey) async {
    if (!kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_seedFlagKey, true);
      return;
    }
    final existing = await _firestore.getCollection(_collection);
    for (final doc in existing) {
      await _firestore.deleteDocument(_collection, doc['id'].toString());
    }
    final raw = await rootBundle.loadString('assets/data/$assetName.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    final list = (data[listKey] as List).cast<Map<String, dynamic>>();
    for (final item in list) {
      final id = item['id']?.toString();
      if (id == null || id.isEmpty) {
        await _firestore.addDocument(_collection, item);
      } else {
        await _firestore.setDocument(_collection, id, item);
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seedFlagKey, true);
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    if (!kIsWeb) return [];
    return await _firestore.getCollection(_collection);
  }

  Stream<List<Map<String, dynamic>>> streamAll() {
    if (!kIsWeb) return Stream.value(<Map<String, dynamic>>[]);
    return _firestore.collectionStream(_collection);
  }

  Future<void> add(Map<String, dynamic> data) async {
    if (!kIsWeb) return;
    await _firestore.addDocument(_collection, data);
  }

  Future<void> set(String id, Map<String, dynamic> data) async {
    if (!kIsWeb) return;
    await _firestore.setDocument(_collection, id, data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    if (!kIsWeb) return;
    await _firestore.updateDocument(_collection, id, data);
  }

  Future<void> delete(String id) async {
    if (!kIsWeb) return;
    await _firestore.deleteDocument(_collection, id);
  }

  Future<void> deleteWhere(String id) async {
    if (!kIsWeb) return;
    try {
      await _firestore.deleteDocument(_collection, id);
      return;
    } catch (_) {
      // Fall through to data-field search below
    }
    final results = await _firestore.queryWhere(_collection, 'id', id);
    if (results.isNotEmpty) {
      final docId = results.first['id']?.toString() ?? '';
      if (docId.isNotEmpty) {
        await _firestore.deleteDocument(_collection, docId);
        return;
      }
    }
    throw Exception(
        'No document with id "$id" found in $_collection collection');
  }
}
