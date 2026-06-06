import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../../data/datasources/member_remote_datasource.dart';
import '../../domain/entities/member_entity.dart';
import '../../domain/repositories/member_repository.dart';

class MemberRepositoryImpl implements MemberRepository {
  final MemberRemoteDataSource _dataSource;

  MemberRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<MemberEntity>>> getAllMembers() async {
    try {
      final members = await _dataSource.getAllMembers();
      return Right(members);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, MemberEntity>> getMemberById(
      String memberId) async {
    try {
      final member = await _dataSource.findById(memberId);
      if (member == null) {
        return const Left(ServerFailure('Member not found'));
      }
      return Right(member);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MemberEntity>>> searchMembers(
      String query) async {
    try {
      final members = await _dataSource.searchMembers(query);
      return Right(members);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveMember(MemberEntity member) async {
    try {
      await _dataSource.saveMember(member);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMember(
      String memberId, Map<String, dynamic> data) async {
    return const Left(
        ServerFailure('Update not supported in local mode.'));
  }

  @override
  Future<Either<Failure, void>> updateMemberStatus(
      String memberId, String status) async {
    return const Left(
        ServerFailure('Update not supported in local mode.'));
  }

  @override
  Future<Either<Failure, void>> deleteMember(String memberId) async {
    try {
      await _dataSource.deleteMember(memberId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<MemberEntity>> watchMembers() {
    return _dataSource.streamMembers();
  }
}
