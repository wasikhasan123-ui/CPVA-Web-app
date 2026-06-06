import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/member_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, MemberEntity>> signInWithMobile(
      String mobile, String password);

  Future<Either<Failure, MemberEntity>> signInWithEmail(
      String email, String password);

  Future<Either<Failure, void>> signOut();

  Future<Either<Failure, MemberEntity?>> getCurrentUser();

  Future<Either<Failure, void>> registerMember(Map<String, dynamic> data);

  Future<Either<Failure, void>> sendPasswordReset(String email);

  Future<Either<Failure, bool>> verifyResetCode(
      String email, String code);

  Future<Either<Failure, void>> resetPassword(
      String email, String newPassword);

  Future<Either<Failure, void>> changePassword(
      String memberId, String oldPassword, String newPassword);

  Future<Either<Failure, void>> setPasswordForMember(
      String memberId, String password);

  Future<Either<Failure, String?>> getResetCodeForMobile(String mobile);

  Future<Either<Failure, String>> getEmailForReset(String mobile);

  Stream<MemberEntity?> get authStateChanges;
}
