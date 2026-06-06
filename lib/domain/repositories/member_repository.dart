import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/member_entity.dart';

abstract class MemberRepository {
  Future<Either<Failure, List<MemberEntity>>> getAllMembers();
  Future<Either<Failure, MemberEntity>> getMemberById(String memberId);
  Future<Either<Failure, List<MemberEntity>>> searchMembers(String query);
  Future<Either<Failure, void>> saveMember(MemberEntity member);
  Future<Either<Failure, void>> deleteMember(String memberId);
  Future<Either<Failure, void>> updateMember(
      String memberId, Map<String, dynamic> data);
  Future<Either<Failure, void>> updateMemberStatus(
      String memberId, String status);
  Stream<List<MemberEntity>> watchMembers();
}
