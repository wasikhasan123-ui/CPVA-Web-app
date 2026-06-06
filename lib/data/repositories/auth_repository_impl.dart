import 'dart:convert';
import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/failures.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../data/datasources/email_service.dart';
import '../../data/datasources/member_remote_datasource.dart';
import '../../data/datasources/registration_remote_datasource.dart';
import '../../data/datasources/remote/password_service.dart';
import '../../data/models/member_model.dart';
import '../../domain/entities/member_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final MemberRemoteDataSource _dataSource;
  final RegistrationRemoteDataSource _regDs;
  final PasswordService _passwordService;
  static const String _kLoggedInMemberId = 'logged_in_member_id';
  static const String _kPasswordResetCodePrefix = 'cpva_pw_reset_code_';
  static const String _kPasswordResetMobilePrefix = 'cpva_pw_reset_mobile_';
  static const String _kPasswordResetExpiryPrefix = 'cpva_pw_reset_expiry_';
  static const String _kMemberPasswords = 'cpva_member_passwords_v1';
  static const String _adminMobile = '01853548853';

  AuthRepositoryImpl(this._dataSource, this._regDs, this._passwordService);

  String get _defaultPassword {
    return 'cpva2026';
  }

  String _normalizeMobile(String input) {
    var v = input.trim().replaceAll(RegExp(r'[^\d]'), '');
    if (v.startsWith('880') && v.length > 3) {
      v = '0${v.substring(3)}';
    }
    return v;
  }

  String _hashPassword(String password) {
    return base64Url.encode(utf8.encode('cpva_v1_$password'));
  }

  bool _verifyPassword(String password, String hash) {
    if (hash.isEmpty) return false;
    return _hashPassword(password) == hash;
  }

  @override
  Future<Either<Failure, MemberEntity>> signInWithMobile(
      String mobile, String password) async {
    try {
      final cleanMobile = _normalizeMobile(mobile);
      if (cleanMobile.length < 11 || !cleanMobile.startsWith('01')) {
        return const Left(AuthFailure(
            'Invalid mobile number format. Use 01XXXXXXXXX'));
      }
      final member = await _dataSource.findByMobile(cleanMobile);
      if (member == null) {
        return const Left(AuthFailure(
            'No member found with this mobile number.'));
      }

      final storedHash = await _getStoredPasswordHash(member.id);
      if (storedHash == null) {
        return const Left(AuthFailure(
            'Password not set. Please reset your password.'));
      }
      if (!_verifyPassword(password, storedHash)) {
        return const Left(AuthFailure('Incorrect password.'));
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLoggedInMemberId, member.id);
      return Right(member);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MemberEntity>> signInWithEmail(
      String email, String password) async {
    try {
      final all = await _dataSource.getAllMembers();
      MemberModel? found;
      for (final m in all) {
        if (m.email.toLowerCase() == email.toLowerCase()) {
          found = m;
          break;
        }
      }
      if (found == null) {
        return const Left(AuthFailure('No admin found with this email'));
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLoggedInMemberId, found.id);
      return Right(found);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kLoggedInMemberId);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MemberEntity?>> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_kLoggedInMemberId);
      if (id == null) return const Right(null);
      final member = await _dataSource.findById(id);
      return Right(member);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> registerMember(
      Map<String, dynamic> data) async {
    try {
      final mobileRaw = (data['mobile'] ?? '').toString();
      final cleanMobile = _normalizeMobile(mobileRaw);
      if (cleanMobile.length < 11 || !cleanMobile.startsWith('01')) {
        return const Left(AuthFailure(
            'Invalid mobile number. Use 01XXXXXXXXX format.'));
      }
      final existing = await _regDs.findByMobile(cleanMobile);
      if (existing != null) {
        return const Left(AuthFailure(
            'You have already submitted an application.'));
      }
      final app = MembershipApplication(
        id: 'APP-${DateTime.now().millisecondsSinceEpoch}',
        name: (data['name'] ?? '').toString(),
        mobile: cleanMobile,
        email: (data['email'] ?? '').toString(),
        gender: (data['gender'] ?? '').toString(),
        fatherName: (data['fatherName'] ?? '').toString(),
        motherName: (data['motherName'] ?? '').toString(),
        bloodGroup: (data['bloodGroup'] ?? '').toString(),
        bvcRegNo: (data['bvcRegNo'] ?? '').toString(),
        dvmInstitute: (data['dvmInstitute'] ?? '').toString(),
        specialization: (data['specialization'] ?? '').toString(),
        workType: (data['workType'] ?? '').toString(),
        instituteName: (data['instituteName'] ?? '').toString(),
        address: (data['address'] ?? '').toString(),
        paymentAmount: (data['paymentAmount'] ?? '').toString(),
        paymentMethod: (data['paymentMethod'] ?? '').toString(),
        transactionId: (data['transactionId'] ?? '').toString(),
        password: (data['password'] ?? '').toString(),
        submittedAt: DateTime.now().toIso8601String(),
      );
      await _regDs.submitApplication(app);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordReset(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final emailService = EmailService();
      if (!emailService.isValidEmail(cleanEmail)) {
        return const Left(AuthFailure('Please enter a valid email address.'));
      }
      final all = await _dataSource.getAllMembers();
      MemberModel? member;
      for (final m in all) {
        if (m.email.toLowerCase() == cleanEmail) {
          member = m;
          break;
        }
      }
      if (member == null) {
        return const Left(AuthFailure(
            'No account found with this email address.'));
      }
      final rng = Random();
      final code = (100000 + rng.nextInt(900000)).toString();
      try {
        await emailService.sendVerificationCode(
          toEmail: member.email,
          code: code,
          memberName: member.name,
        );
      } catch (e) {
        return Left(AuthFailure(
            'Failed to send email: $e. Please check Resend API configuration.'));
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_kPasswordResetCodePrefix$cleanEmail', code);
      await prefs.setString(
          '$_kPasswordResetMobilePrefix$cleanEmail', member.id);
      await prefs.setString(
          '$_kPasswordResetExpiryPrefix$cleanEmail',
          DateTime.now()
              .add(const Duration(minutes: 15))
              .toIso8601String());
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyResetCode(
      String email, String code) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString('$_kPasswordResetCodePrefix$cleanEmail');
      final expiryStr =
          prefs.getString('$_kPasswordResetExpiryPrefix$cleanEmail');
      if (stored == null || expiryStr == null) {
        return const Left(AuthFailure(
            'No reset request found. Please request a new code.'));
      }
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry == null || DateTime.now().isAfter(expiry)) {
        return const Left(AuthFailure('Code expired. Please request a new one.'));
      }
      if (stored != code) {
        return const Left(AuthFailure('Invalid verification code.'));
      }
      return const Right(true);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(
      String email, String newPassword) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final prefs = await SharedPreferences.getInstance();
      final memberId =
          prefs.getString('$_kPasswordResetMobilePrefix$cleanEmail');
      if (memberId == null) {
        return const Left(AuthFailure('Reset session expired. Try again.'));
      }
      await _savePasswordHash(memberId, newPassword);
      await prefs.remove('$_kPasswordResetCodePrefix$cleanEmail');
      await prefs.remove('$_kPasswordResetMobilePrefix$cleanEmail');
      await prefs.remove('$_kPasswordResetExpiryPrefix$cleanEmail');
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword(
      String memberId, String oldPassword, String newPassword) async {
    try {
      final stored = await _getStoredPasswordHash(memberId);
      if (stored == null) {
        return const Left(AuthFailure(
            'No password set. Please reset via Forgot Password.'));
      }
      if (!_verifyPassword(oldPassword, stored)) {
        return const Left(AuthFailure('Current password is incorrect.'));
      }
      await _savePasswordHash(memberId, newPassword);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setPasswordForMember(
      String memberId, String password) async {
    try {
      await _savePasswordHash(memberId, password);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String?>> getResetCodeForMobile(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('$_kPasswordResetCodePrefix$cleanEmail');
      final memberId =
          prefs.getString('$_kPasswordResetMobilePrefix$cleanEmail');
      if (code == null || memberId == null) {
        return const Right(null);
      }
      return Right(code);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> getEmailForReset(String email) async {
    try {
      final cleanEmail = email.trim().toLowerCase();
      final prefs = await SharedPreferences.getInstance();
      final memberId =
          prefs.getString('$_kPasswordResetMobilePrefix$cleanEmail');
      if (memberId == null) {
        return const Left(AuthFailure('No reset session.'));
      }
      final member = await _dataSource.findById(memberId);
      if (member == null) {
        return const Left(AuthFailure('Member not found.'));
      }
      return Right(member.email);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  Future<String?> _getStoredPasswordHash(String memberId) async {
    if (kIsWeb) {
      final remote = await _passwordService.getPasswordHash(memberId);
      if (remote != null && remote.isNotEmpty) return remote;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMemberPasswords);
    if (raw != null && raw.isNotEmpty) {
      final map = json.decode(raw) as Map<String, dynamic>;
      final hash = map[memberId]?.toString();
      if (hash != null && hash.isNotEmpty) return hash;
    }
    if (_isAdminMemberId(memberId)) {
      return _hashPassword('(admin)');
    }
    return _hashPassword(_defaultPassword);
  }

  bool _isAdminMemberId(String memberId) {
    return memberId == '1' ||
        memberId == 'm_1' ||
        memberId == 'm_8021' ||
        memberId == _adminMobile;
  }

  Future<void> _savePasswordHash(String memberId, String password) async {
    final hash = _hashPassword(password);
    if (kIsWeb) {
      await _passwordService.setPassword(memberId, hash);
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kMemberPasswords);
    Map<String, dynamic> map = {};
    if (raw != null && raw.isNotEmpty) {
      map = json.decode(raw) as Map<String, dynamic>;
    }
    map[memberId] = hash;
    await prefs.setString(_kMemberPasswords, json.encode(map));
  }

  Stream<MemberEntity?> get authStateChanges {
    return Stream.empty();
  }
}
