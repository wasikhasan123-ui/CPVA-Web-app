part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class MemberLoginRequested extends AuthEvent {
  final String mobile;
  final String password;

  const MemberLoginRequested({required this.mobile, required this.password});

  @override
  List<Object?> get props => [mobile, password];
}

class AdminLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AdminLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final Map<String, dynamic> data;

  const RegisterRequested(this.data);

  @override
  List<Object?> get props => [data];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class AuthStateChanged extends AuthEvent {
  final MemberEntity? user;

  const AuthStateChanged(this.user);

  @override
  List<Object?> get props => [user];
}

class PasswordResetRequested extends AuthEvent {
  final String email;

  const PasswordResetRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class PasswordResetCodeVerified extends AuthEvent {
  final String email;
  final String code;

  const PasswordResetCodeVerified({
    required this.email,
    required this.code,
  });

  @override
  List<Object?> get props => [email, code];
}

class PasswordResetCompleted extends AuthEvent {
  final String email;
  final String newPassword;

  const PasswordResetCompleted({
    required this.email,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [email, newPassword];
}

class PasswordChanged extends AuthEvent {
  final String memberId;
  final String oldPassword;
  final String newPassword;

  const PasswordChanged({
    required this.memberId,
    required this.oldPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props => [memberId, oldPassword, newPassword];
}
