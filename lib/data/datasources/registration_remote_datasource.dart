import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'remote/firestore_service.dart';

class MembershipApplication {
  final String id;
  final String name;
  final String mobile;
  final String email;
  final String gender;
  final String fatherName;
  final String motherName;
  final String bloodGroup;
  final String dvmInstitute;
  final String specialization;
  final String workType;
  final String instituteName;
  final String address;
  final String bvcRegNo;
  final String paymentAmount;
  final String paymentMethod;
  final String transactionId;
  final String password;
  final String authUid;
  final String submittedAt;
  String status;
  String? rejectionReason;

  MembershipApplication({
    required this.id,
    required this.name,
    required this.mobile,
    this.email = '',
    this.gender = '',
    this.fatherName = '',
    this.motherName = '',
    this.bloodGroup = '',
    this.dvmInstitute = '',
    this.specialization = '',
    this.workType = '',
    this.instituteName = '',
    this.address = '',
    this.bvcRegNo = '',
    this.paymentAmount = '',
    this.paymentMethod = '',
    this.transactionId = '',
    this.password = '',
    this.authUid = '',
    required this.submittedAt,
    this.status = 'pending',
    this.rejectionReason,
  });

  String get mobileClean => mobile.replaceAll(RegExp(r'[^\d]'), '');

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mobile': mobile,
        'email': email,
        'gender': gender,
        'fatherName': fatherName,
        'motherName': motherName,
        'bloodGroup': bloodGroup,
        'dvmInstitute': dvmInstitute,
        'specialization': specialization,
        'workType': workType,
        'instituteName': instituteName,
        'address': address,
        'bvcRegNo': bvcRegNo,
        'paymentAmount': paymentAmount,
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        'password': password,
        'authUid': authUid,
        'submittedAt': submittedAt,
        'status': status,
        'rejectionReason': rejectionReason,
      };

  factory MembershipApplication.fromJson(Map<String, dynamic> json) {
    return MembershipApplication(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? '').toString(),
      mobile: (json['mobile'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      fatherName: (json['fatherName'] ?? '').toString(),
      motherName: (json['motherName'] ?? '').toString(),
      bloodGroup: (json['bloodGroup'] ?? '').toString(),
      dvmInstitute: (json['dvmInstitute'] ?? '').toString(),
      specialization: (json['specialization'] ?? '').toString(),
      workType: (json['workType'] ?? '').toString(),
      instituteName: (json['instituteName'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      bvcRegNo: (json['bvcRegNo'] ?? '').toString(),
      paymentAmount: (json['paymentAmount'] ?? '').toString(),
      paymentMethod: (json['paymentMethod'] ?? '').toString(),
      transactionId: (json['transactionId'] ?? '').toString(),
      password: (json['password'] ?? '').toString(),
      authUid: (json['authUid'] ?? '').toString(),
      submittedAt: (json['submittedAt'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }
}

class RegistrationRemoteDataSource {
  final FirestoreService _firestore;
  static const _collection = 'registrations';
  static const _kApplications = 'cpva_membership_applications_v1';

  RegistrationRemoteDataSource(this._firestore);

  List<MembershipApplication>? _cached;

  Future<List<MembershipApplication>> _loadAll() async {
    if (_cached != null) return _cached!;
    if (kIsWeb) {
      final data = await _firestore.getCollection(_collection);
      _cached = data
          .map((d) => MembershipApplication.fromJson(Map<String, dynamic>.from(d)))
          .toList();
      return _cached!;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kApplications);
    if (raw == null || raw.isEmpty) {
      _cached = [];
      return _cached!;
    }
    final list = json.decode(raw) as List<dynamic>;
    _cached = list
        .map((e) => MembershipApplication.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cached!;
  }

  void _invalidateCache() {
    _cached = null;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _cached!.map((a) => a.toJson()).toList();
    await prefs.setString(_kApplications, json.encode(list));
  }

  Future<List<MembershipApplication>> getPendingApplications() async {
    final all = await _loadAll();
    return all.where((a) => a.status == 'pending').toList()
      ..sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
  }

  Future<List<MembershipApplication>> getAllApplications() async {
    return await _loadAll();
  }

  Future<void> submitApplication(MembershipApplication app) async {
    if (kIsWeb) {
      await _firestore.setDocument(_collection, app.id, app.toJson());
      _invalidateCache();
    } else {
      await _loadAll();
      _cached!.add(app);
      await _persist();
    }
  }

  Future<void> approveApplication(String appId) async {
    await _loadAll();
    final idx = _cached!.indexWhere((a) => a.id == appId);
    if (idx < 0) return;
    _cached![idx].status = 'approved';
    if (kIsWeb) {
      await _firestore.updateDocument(_collection, appId, {'status': 'approved'});
    } else {
      await _persist();
    }
  }

  Future<void> rejectApplication(String appId, String reason) async {
    await _loadAll();
    final idx = _cached!.indexWhere((a) => a.id == appId);
    if (idx < 0) return;
    _cached![idx].status = 'rejected';
    _cached![idx].rejectionReason = reason;
    if (kIsWeb) {
      await _firestore.updateDocument(_collection, appId, {
        'status': 'rejected',
        'rejectionReason': reason,
      });
    } else {
      await _persist();
    }
  }

  Future<MembershipApplication?> findByMobile(String mobile) async {
    final all = await _loadAll();
    final clean = mobile.replaceAll(RegExp(r'[^\d]'), '');
    try {
      return all.firstWhere((a) => a.mobileClean == clean);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteApplication(String appId) async {
    await _loadAll();
    _cached!.removeWhere((a) => a.id == appId);
    if (kIsWeb) {
      await _firestore.deleteDocument(_collection, appId);
    } else {
      await _persist();
    }
  }
}
