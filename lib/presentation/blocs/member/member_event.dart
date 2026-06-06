part of 'member_bloc.dart';

abstract class MemberEvent extends Equatable {
  const MemberEvent();

  @override
  List<Object?> get props => [];
}

class LoadMembers extends MemberEvent {
  const LoadMembers();
}

class SearchMembers extends MemberEvent {
  final String query;

  const SearchMembers(this.query);

  @override
  List<Object?> get props => [query];
}

class LoadMemberDetails extends MemberEvent {
  final String memberId;

  const LoadMemberDetails(this.memberId);

  @override
  List<Object?> get props => [memberId];
}

class UpdateMemberStatus extends MemberEvent {
  final String memberId;
  final String status;

  const UpdateMemberStatus({required this.memberId, required this.status});

  @override
  List<Object?> get props => [memberId, status];
}
