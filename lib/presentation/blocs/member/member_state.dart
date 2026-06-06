part of 'member_bloc.dart';

abstract class MemberState extends Equatable {
  const MemberState();

  @override
  List<Object?> get props => [];
}

class MemberInitial extends MemberState {
  const MemberInitial();
}

class MemberLoading extends MemberState {
  const MemberLoading();
}

class MembersLoaded extends MemberState {
  final List<MemberEntity> members;

  const MembersLoaded(this.members);

  @override
  List<Object?> get props => [members];
}

class MemberDetailsLoaded extends MemberState {
  final MemberEntity member;

  const MemberDetailsLoaded(this.member);

  @override
  List<Object?> get props => [member];
}

class MemberError extends MemberState {
  final String message;

  const MemberError(this.message);

  @override
  List<Object?> get props => [message];
}
