import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/failures.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../data/datasources/member_remote_datasource.dart';
import '../../data/datasources/registration_remote_datasource.dart';
import '../../data/datasources/remote/firestore_service.dart';
import '../../data/datasources/remote/password_service.dart';
import '../../domain/entities/member_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final MemberRemoteDataSource _dataSource;
  final RegistrationRemoteDataSource _regDs;
  final PasswordService _passwordService;
  final FirestoreService _firestoreService;
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
  static const String _kLoggedInMemberId = 'logged_in_member_id';
  static const String _kPasswordResetCodePrefix = 'cpva_pw_reset_code_';
  static const String _kPasswordResetMobilePrefix = 'cpva_pw_reset_mobile_';
  static const String _kPasswordResetExpiryPrefix = 'cpva_pw_reset_expiry_';
  static const String _kMemberPasswords = 'cpva_member_passwords_v1';
  static const String _adminMobile = '01853548853';
  static const String _memberIndexCollection = 'memberIndex';

  AuthRepositoryImpl(
    this._dataSource,
    this._regDs,
    this._passwordService,
    this._firestoreService,
  );

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

  Future<MemberEntity?> _findMemberByEmail(String email) async {
    final member = await _dataSource.findByEmail(email);
    return member;
  }

  Future<MemberEntity?> _findMemberByMobile(String mobile) async {
    final cleanMobile = _normalizeMobile(mobile);
    if (cleanMobile.length < 11 || !cleanMobile.startsWith('01')) {
      return null;
    }
    return await _dataSource.findByMobile(cleanMobile);
  }

  /// Look up a member's email from their mobile number.
  /// First tries the public memberIndex collection (works without auth).
  /// Falls back to the full members list (requires auth — may fail at login time).
  Future<String?> _lookupEmailByMobile(String cleanMobile) async {
    // 1. Try memberIndex (public, no auth needed)
    if (kIsWeb) {
      try {
        final doc = await _firestoreService.getDocument(
          _memberIndexCollection,
          cleanMobile,
        );
        if (doc != null) {
          final email = (doc['email'] ?? '').toString().trim();
          if (email.isNotEmpty) return email;
        }
      } catch (_) {
        // memberIndex read failed — try fallback
      }
    }

    // 2. Fall back to full member list (bundled JSON + Firestore if authed)
    final member = await _dataSource.findByMobile(cleanMobile);
    if (member != null && member.email.trim().isNotEmpty) {
      return member.email.trim();
    }

    return null;
  }

  Future<Either<Failure, MemberEntity>> _firebaseLogin(
    String email,
    String password,
  ) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return const Left(AuthFailure('Login failed. Please try again.'));
      }

      if (!firebaseUser.emailVerified) {
        await _firebaseAuth.signOut();
        return const Left(AuthFailure(
          'Please verify your email before logging in.',
        ));
      }

      final member = await _findMemberByEmail(email);
      if (member == null) {
        await _firebaseAuth.signOut();
        return const Left(AuthFailure(
          'Account not found. Please contact admin.',
        ));
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLoggedInMemberId, member.id);
      return Right(member);
    } on fb_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return const Left(AuthFailure(
              'Account not found. Please contact admin.'));
        case 'wrong-password':
        case 'invalid-credential':
          return const Left(
              AuthFailure('Incorrect email or password.'));
        case 'too-many-requests':
          return const Left(AuthFailure(
              'Too many attempts. Please try again later.'));
        case 'network-request-failed':
          return const Left(AuthFailure(
              'Network error. Please check your connection.'));
        default:
          return Left(AuthFailure(e.message ?? 'Login failed.'));
      }
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MemberEntity>> signInWithMobile(
    String mobileOrEmail,
    String password,
  ) async {
    if (mobileOrEmail.contains('@')) {
      return _firebaseLogin(mobileOrEmail.trim(), password);
    }

    try {
      final cleanMobile = _normalizeMobile(mobileOrEmail);
      if (cleanMobile.length < 11 || !cleanMobile.startsWith('01')) {
        return const Left(
            AuthFailure('Invalid mobile number format. Use 01XXXXXXXXX'));
      }

      final email = await _lookupEmailByMobile(cleanMobile);
      if (email == null || email.isEmpty) {
        return const Left(
            AuthFailure('No member found with this mobile number.'));
      }

      return _firebaseLogin(email, password);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MemberEntity>> signInWithEmail(
    String email,
    String password,
  ) async {
    return _firebaseLogin(email.trim(), password);
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _firebaseAuth.signOut();
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
      final firebaseUser = _firebaseAuth.currentUser;

      if (firebaseUser != null) {
        final member = await _findMemberByEmail(firebaseUser.email ?? '');
        if (member != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_kLoggedInMemberId, member.id);
          return Right(member);
        }
      }

      // No Firebase Auth session → user is not logged in.
      // They will be redirected to the login page by the router.
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> registerMember(
    Map<String, dynamic> data,
  ) async {
    try {
      final mobileRaw = (data['mobile'] ?? '').toString();
      final cleanMobile = _normalizeMobile(mobileRaw);
      if (cleanMobile.length < 11 || !cleanMobile.startsWith('01')) {
        return const Left(
            AuthFailure('Invalid mobile number. Use 01XXXXXXXXX format.'));
      }
      final existing = await _regDs.findByMobile(cleanMobile);
      if (existing != null) {
        return const Left(
            AuthFailure('You have already submitted an application.'));
      }
      final authUid = (data['authUid'] ?? '').toString();
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
        password: '',
        authUid: authUid,
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
      if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
        return const Left(
            AuthFailure('Please enter a valid email address.'));
      }
      await _firebaseAuth.sendPasswordResetEmail(email: cleanEmail);
      return const Right(null);
    } on fb_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return const Left(AuthFailure(
              'No account found with this email address.'));
        default:
          return Left(AuthFailure(
              'Failed to send reset email: ${e.message}'));
      }
    } catch (e) {
      return Left(AuthFailure('Failed to send reset email: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyResetCode(
    String email,
    String code,
  ) async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, void>> resetPassword(
    String email,
    String newPassword,
  ) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, void>> changePassword(
    String memberId,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null || user.email == null) {
        return const Left(AuthFailure('Please login again.'));
      }
      final credential = fb_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: oldPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return const Right(null);
    } on fb_auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          return const Left(
              AuthFailure('Current password is incorrect.'));
        case 'weak-password':
          return const Left(AuthFailure(
              'New password must be at least 6 characters.'));
        default:
          return Left(
              AuthFailure('Failed to change password: ${e.message}'));
      }
    } catch (e) {
      return Left(AuthFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setPasswordForMember(
    String memberId,
    String password,
  ) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, String?>> getResetCodeForMobile(
    String email,
  ) async {
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
      return _hashPassword('admin');
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
