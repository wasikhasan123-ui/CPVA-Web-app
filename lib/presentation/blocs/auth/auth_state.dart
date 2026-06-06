part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final MemberEntity user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  final String message;

  const AuthUnauthenticated(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthRegistered extends AuthState {
  const AuthRegistered();
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthPasswordResetCodeSent extends AuthState {
  final String email;
  final String devCode;

  const AuthPasswordResetCodeSent({
    required this.email,
    required this.devCode,
  });

  @override
  List<Object?> get props => [email, devCode];
}

class AuthPasswordResetCodeVerified extends AuthState {
  final String email;

  const AuthPasswordResetCodeVerified(this.email);

  @override
  List<Object?> get props => [email];
}

class AuthPasswordResetSuccess extends AuthState {
  const AuthPasswordResetSuccess();
}

class AuthPasswordChanged extends AuthState {
  const AuthPasswordChanged();
}
