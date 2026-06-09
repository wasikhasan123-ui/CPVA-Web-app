import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/member_entity.dart';
import '../models/member_model.dart';
import 'remote/firestore_service.dart';

class MemberRemoteDataSource {
  final FirestoreService _firestore;
  static const _collection = 'members';
  static const _kSeeded = 'cpva_members_seeded_v1';
  static const _kOverrides = 'cpva_member_overrides_v1';
  static const _kDeletes = 'cpva_member_deletes_v1';

  List<MemberModel>? _base;
  List<MemberModel>? _overrides;
  Set<String>? _deletes;
  List<MemberModel>? _cached;

  MemberRemoteDataSource(this._firestore);

  Future<List<MemberModel>> _loadBase() async {
    if (_base != null) return _base!;
    final jsonString =
        await rootBundle.loadString('assets/data/members.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    final membersList = jsonData['members'] as List<dynamic>;
    _base = membersList
        .map((e) => MemberModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return _base!;
  }

  String _cleanMobileKey(String value) {
    var v = value.trim().replaceAll(RegExp(r'[^\d+]'), '');

    if (v.startsWith('+880')) {
      v = '0${v.substring(4)}';
    } else if (v.startsWith('880') && v.length > 10) {
      v = '0${v.substring(3)}';
    }

    v = v.replaceAll(RegExp(r'[^\d]'), '');

    if (v.length == 10 && !v.startsWith('0')) {
      v = '0$v';
    }

    return v;
  }

  Future<List<MemberModel>> _loadOverrides() async {
    if (_overrides != null) return _overrides!;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kOverrides);
    if (raw == null || raw.isEmpty) {
      _overrides = [];
      return _overrides!;
    }
    final list = json.decode(raw) as List<dynamic>;
    _overrides =
        list.map((e) => MemberModel.fromJson(e as Map<String, dynamic>)).toList();
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

  Future<bool> _ensureSeeded() async {
    final prefs = await SharedPreferences.getInstance();

    if (!kIsWeb) {
      await prefs.setBool(_kSeeded, true);
      return false;
    }

    final base = await _loadBase();

    List<Map<String, dynamic>> remote = [];
    try {
      remote = await _firestore.getCollection(_collection);
    } catch (e) {
      // If Firestore read fails, do not block local fallback.
      return false;
    }

    final existingKeys = <String>{};

    for (final doc in remote) {
      final id = (doc['id'] ?? '').toString();
      final mobile = (doc['mobile'] ?? '').toString();

      final cleanId = _cleanMobileKey(id);
      final cleanMobile = _cleanMobileKey(mobile);

      if (id.isNotEmpty) existingKeys.add(id);
      if (cleanId.isNotEmpty) existingKeys.add(cleanId);
      if (cleanMobile.isNotEmpty) existingKeys.add(cleanMobile);
    }

    var wroteAny = false;

    for (final member in base) {
      final memberId = member.id;
      final memberIdClean = _cleanMobileKey(member.id);
      final memberMobileClean = _cleanMobileKey(member.mobile);

      final alreadyExists =
          existingKeys.contains(memberId) ||
          existingKeys.contains(memberIdClean) ||
          existingKeys.contains(memberMobileClean);

      if (alreadyExists) {
        continue;
      }

      try {
        await _firestore.setDocument(
          _collection,
          member.id,
          member.toJson(),
        );

        if (memberId.isNotEmpty) existingKeys.add(memberId);
        if (memberIdClean.isNotEmpty) existingKeys.add(memberIdClean);
        if (memberMobileClean.isNotEmpty) existingKeys.add(memberMobileClean);

        wroteAny = true;
      } catch (e) {
        // Continue trying other members.
      }
    }

    await prefs.setBool(_kSeeded, true);
    return wroteAny;
  }

  Future<List<MemberModel>> _allLocal() async {
    if (_cached != null) return _cached!;
    final base = await _loadBase();
    final overrides = await _loadOverrides();
    final deletes = await _loadDeletes();
    final result = <MemberModel>[];
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
      if (!base.any((b) => b.id == o.id)) result.add(o);
    }
    _cached = result;
    return _cached!;
  }

  Future<List<MemberModel>> getAllMembers() async {
    if (!kIsWeb) return _allLocal();

    await _ensureSeeded();

    List<Map<String, dynamic>> remote = [];

    try {
      remote = await _firestore.getCollection(_collection);
    } catch (e) {
      return _allLocal();
    }

    final base = await _loadBase();

    if (remote.isEmpty) {
      return base;
    }

    final result = remote
        .map((d) => MemberModel.fromJson({...d, 'id': d['id'].toString()}))
        .toList();

    // Emergency fallback:
    // If Firestore is missing original bundled members, mix them in locally
    // so login can work even before admin restore is used.
    final existingKeys = <String>{};

    for (final member in result) {
      final idKey = member.id;
      final cleanId = _cleanMobileKey(member.id);
      final cleanMobile = _cleanMobileKey(member.mobile);

      if (idKey.isNotEmpty) existingKeys.add(idKey);
      if (cleanId.isNotEmpty) existingKeys.add(cleanId);
      if (cleanMobile.isNotEmpty) existingKeys.add(cleanMobile);
    }

    for (final member in base) {
      final memberId = member.id;
      final cleanId = _cleanMobileKey(member.id);
      final cleanMobile = _cleanMobileKey(member.mobile);

      final alreadyExists =
          existingKeys.contains(memberId) ||
          existingKeys.contains(cleanId) ||
          existingKeys.contains(cleanMobile);

      if (!alreadyExists) {
        result.add(member);

        if (memberId.isNotEmpty) existingKeys.add(memberId);
        if (cleanId.isNotEmpty) existingKeys.add(cleanId);
        if (cleanMobile.isNotEmpty) existingKeys.add(cleanMobile);
      }
    }

    return result;
  }

  Stream<List<MemberModel>> streamMembers() {
    if (!kIsWeb) {
      return Stream.fromFuture(_allLocal());
    }
    return _firestore
        .collectionStream(_collection)
        .asyncMap((data) async => data
            .map((d) => MemberModel.fromJson({...d, 'id': d['id'].toString()}))
            .toList());
  }

  Future<MemberModel?> findByMobile(String mobile) async {
    final all = await getAllMembers();
    final cleanInput = mobile.replaceAll(RegExp(r'[^\d]'), '');
    try {
      return all.firstWhere((m) => m.mobileClean == cleanInput);
    } catch (_) {
      return null;
    }
  }

  Future<MemberModel?> findById(String id) async {
    final all = await getAllMembers();
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<MemberModel?> findByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isEmpty) return null;
    final all = await getAllMembers();
    try {
      return all.firstWhere(
        (m) => m.email.trim().toLowerCase() == cleanEmail,
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<MemberModel>> searchMembers(String query) async {
    final all = await getAllMembers();
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return all;
    return all.where((m) {
      return m.name.toLowerCase().contains(q) ||
          m.mobile.contains(q) ||
          m.bvcRegNo.toLowerCase().contains(q) ||
          m.email.toLowerCase().contains(q) ||
          m.instituteName.toLowerCase().contains(q) ||
          m.specialization.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> saveMember(MemberEntity entity) async {
    final member = MemberModel(
      id: entity.id,
      name: entity.name,
      nameBn: entity.nameBn,
      fatherName: entity.fatherName,
      motherName: entity.motherName,
      gender: entity.gender,
      permanentAddress: entity.permanentAddress,
      mailingAddress: entity.mailingAddress,
      mobile: entity.mobile,
      email: entity.email,
      emergencyContact: entity.emergencyContact,
      bvcRegNo: entity.bvcRegNo,
      dateOfBirth: entity.dateOfBirth,
      bloodGroup: entity.bloodGroup,
      dvmInstitute: entity.dvmInstitute,
      msc: entity.msc,
      phd: entity.phd,
      experience: entity.experience,
      specialization: entity.specialization,
      workType: entity.workType,
      instituteName: entity.instituteName,
      interests: entity.interests,
      photoUrl: entity.photoUrl,
      licenseUrl: entity.licenseUrl,
      authUid: entity.authUid,
    );
    if (kIsWeb) {
      await _ensureSeeded();
      await _firestore.setDocument(_collection, member.id, member.toJson());
    }
    await _loadOverrides();
    await _loadDeletes();

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

  Future<void> deleteMember(String id) async {
    if (kIsWeb) {
      try {
        await _firestore.deleteDocument(_collection, id);
      } catch (_) {}
    }
    await _loadOverrides();
    await _loadDeletes();
    _overrides!.removeWhere((m) => m.id == id);
    _deletes!.add(id);
    await _persistOverrides();
    await _persistDeletes();
    _invalidateCache();
  }

  Future<void> resetAdminChanges() async {
    if (kIsWeb) {
      try {
        final remote = await _firestore.getCollection(_collection);
        for (final doc in remote) {
          await _firestore.deleteDocument(_collection, doc['id'].toString());
        }
        final base = await _loadBase();
        for (final m in base) {
          await _firestore.setDocument(_collection, m.id, m.toJson());
        }
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kOverrides);
    await prefs.remove(_kDeletes);
    await prefs.remove(_kSeeded);
    _overrides = [];
    _deletes = {};
    _invalidateCache();
  }
}
