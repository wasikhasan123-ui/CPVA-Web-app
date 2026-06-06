import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/executive_member_entity.dart';
import '../models/executive_member_model.dart';

class ExecutiveLocalDataSource {
  static const _kOverrides = 'cpva_exec_overrides_v1';
  static const _kDeletes = 'cpva_exec_deletes_v1';

  List<ExecutiveMemberModel>? _base;
  List<ExecutiveMemberModel>? _overrides;
  Set<String>? _deletes;
  List<ExecutiveMemberModel>? _cached;

  Future<List<ExecutiveMemberModel>> _loadBase() async {
    if (_base != null) return _base!;
    final jsonString =
        await rootBundle.loadString('assets/data/executives.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    final list = jsonData['executives'] as List<dynamic>;
    _base = list
        .map((e) =>
            ExecutiveMemberModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return _base!;
  }

  Future<List<ExecutiveMemberModel>> _loadOverrides() async {
    if (_overrides != null) return _overrides!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kOverrides);
    if (raw == null || raw.isEmpty) {
      _overrides = [];
      return _overrides!;
    }
    final list = json.decode(raw) as List<dynamic>;
    _overrides = list
        .map((e) =>
            ExecutiveMemberModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return _overrides!;
  }

  Future<Set<String>> _loadDeletes() async {
    if (_deletes != null) return _deletes!;
    final prefs = await SharedPreferences.getInstance();
    _deletes = (prefs.getStringList(_kDeletes) ?? []).toSet();
    return _deletes!;
  }

  Future<void> _persistOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _overrides!.map((m) => m.toJson()).toList();
    await prefs.setString(_kOverrides, json.encode(list));
  }

  Future<void> _persistDeletes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kDeletes, _deletes!.toList());
  }

  void _invalidateCache() {
    _cached = null;
  }

  Future<List<ExecutiveMemberModel>> getAll() async {
    if (_cached != null) return _cached!;
    final base = await _loadBase();
    final overrides = await _loadOverrides();
    final deletes = await _loadDeletes();

    final result = <ExecutiveMemberModel>[];
    final overrideIds = {for (final m in overrides) m.id};

    for (final m in base) {
      if (deletes.contains(m.id)) continue;
      if (overrideIds.contains(m.id)) {
        result.add(overrides.firstWhere((o) => o.id == m.id));
      } else {
        result.add(m);
      }
    }
    for (final o in overrides) {
      if (!base.any((b) => b.id == o.id)) {
        result.add(o);
      }
    }
    _cached = result;
    return _cached!;
  }

  Future<ExecutiveMemberModel?> findById(String id) async {
    final all = await getAll();
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(ExecutiveMemberEntity entity) async {
    await _loadOverrides();
    await _loadDeletes();
    final member = ExecutiveMemberModel(
      id: entity.id,
      name: entity.name,
      nameBn: entity.nameBn,
      designation: entity.designation,
      designationBn: entity.designationBn,
      mobile: entity.mobile,
      photoUrl: entity.photoUrl,
    );
    final idx = _overrides!.indexWhere((m) => m.id == member.id);
    if (idx >= 0) {
      _overrides![idx] = member;
    } else {
      _overrides!.add(member);
    }
    _deletes!.remove(member.id);
    await _persistOverrides();
    await _persistDeletes();
    _invalidateCache();
  }

  Future<void> delete(String id) async {
    await _loadOverrides();
    await _loadDeletes();
    _overrides!.removeWhere((m) => m.id == id);
    _deletes!.add(id);
    await _persistOverrides();
    await _persistDeletes();
    _invalidateCache();
  }

  Future<void> resetChanges() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOverrides);
    await prefs.remove(_kDeletes);
    _overrides = [];
    _deletes = {};
    _invalidateCache();
  }
}
