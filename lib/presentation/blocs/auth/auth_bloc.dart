import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/member_entity.dart';
import '../../../domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<MemberLoginRequested>(_onMemberLoginRequested);
    on<AdminLoginRequested>(_onAdminLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<PasswordResetRequested>(_onPasswordResetRequested);
    on<PasswordResetCodeVerified>(_onPasswordResetCodeVerified);
    on<PasswordResetCompleted>(_onPasswordResetCompleted);
    on<PasswordChanged>(_onPasswordChanged);
  }

  Future<void> _onAuthCheckRequested(
      AuthCheckRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _authRepository.getCurrentUser();
    result.fold(
      (failure) => emit(AuthUnauthenticated(failure.message)),
      (user) {
        if (user != null) {
          emit(AuthAuthenticated(user));
        } else {
          emit(const AuthUnauthenticated(''));
        }
      },
    );
  }

  Future<void> _onMemberLoginRequested(
      MemberLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _authRepository.signInWithMobile(
      event.mobile,
      event.password,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> _onAdminLoginRequested(
      AdminLoginRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _authRepository.signInWithEmail(
      event.email,
      event.password,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) {
        if (user.isAdmin) {
          emit(AuthAuthenticated(user));
        } else {
          emit(const AuthError('You are not authorized as admin'));
        }
      },
    );
  }

  Future<void> _onRegisterRequested(
      RegisterRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _authRepository.registerMember(event.data);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthRegistered()),
    );
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.signOut();
    emit(const AuthUnauthenticated(''));
  }

  Future<void> _onAuthStateChanged(
      AuthStateChanged event, Emitter<AuthState> emit) async {
    if (event.user != null) {
      emit(AuthAuthenticated(event.user!));
    } else {
      emit(const AuthUnauthenticated(''));
    }
  }

  Future<void> _onPasswordResetRequested(
      PasswordResetRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _authRepository.sendPasswordReset(event.email);
    await result.fold(
      (failure) async => emit(AuthError(failure.message)),
      (_) async {
        final codeResult =
            await _authRepository.getResetCodeForMobile(event.email);
        final code = codeResult.getOrElse(() => null) ?? '';
        emit(AuthPasswordResetCodeSent(
          email: event.email,
          devCode: code,
        ));
      },
    );
  }

  Future<void> _onPasswordResetCodeVerified(
      PasswordResetCodeVerified event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _authRepository.verifyResetCode(
      event.email,
      event.code,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (ok) => emit(AuthPasswordResetCodeVerified(event.email)),
    );
  }

  Future<void> _onPasswordResetCompleted(
      PasswordResetCompleted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _authRepository.resetPassword(
      event.email,
      event.newPassword,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthPasswordResetSuccess()),
    );
  }

  Future<void> _onPasswordChanged(
      PasswordChanged event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await _authRepository.changePassword(
      event.memberId,
      event.oldPassword,
      event.newPassword,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthPasswordChanged()),
    );
  }
}
