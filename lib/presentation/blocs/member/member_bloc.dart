import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/member_entity.dart';
import '../../../domain/repositories/member_repository.dart';

part 'member_event.dart';
part 'member_state.dart';

class MemberBloc extends Bloc<MemberEvent, MemberState> {
  final MemberRepository _memberRepository;

  MemberBloc(this._memberRepository) : super(MemberInitial()) {
    on<LoadMembers>(_onLoadMembers);
    on<SearchMembers>(_onSearchMembers);
    on<LoadMemberDetails>(_onLoadMemberDetails);
    on<UpdateMemberStatus>(_onUpdateMemberStatus);
  }

  Future<void> _onLoadMembers(
      LoadMembers event, Emitter<MemberState> emit) async {
    emit(MemberLoading());
    final result = await _memberRepository.getAllMembers();
    result.fold(
      (failure) => emit(MemberError(failure.message)),
      (members) => emit(MembersLoaded(members)),
    );
  }

  Future<void> _onSearchMembers(
      SearchMembers event, Emitter<MemberState> emit) async {
    emit(MemberLoading());
    final result = await _memberRepository.searchMembers(event.query);
    result.fold(
      (failure) => emit(MemberError(failure.message)),
      (members) => emit(MembersLoaded(members)),
    );
  }

  Future<void> _onLoadMemberDetails(
      LoadMemberDetails event, Emitter<MemberState> emit) async {
    emit(MemberLoading());
    final result = await _memberRepository.getMemberById(event.memberId);
    result.fold(
      (failure) => emit(MemberError(failure.message)),
      (member) => emit(MemberDetailsLoaded(member)),
    );
  }

  Future<void> _onUpdateMemberStatus(
      UpdateMemberStatus event, Emitter<MemberState> emit) async {
    emit(MemberLoading());
    final result = await _memberRepository.updateMemberStatus(
      event.memberId,
      event.status,
    );
    result.fold(
      (failure) => emit(MemberError(failure.message)),
      (_) => add(const LoadMembers()),
    );
  }
}
