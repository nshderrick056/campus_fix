import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/repository_exception.dart';
import '../../models/app_user.dart';

enum AuthStatus { unknown, signedOut, unverified, signedIn }

class AuthState extends Equatable {
  const AuthState._(this.status, this.user);

  const AuthState.unknown() : this._(AuthStatus.unknown, null);
  const AuthState.signedOut() : this._(AuthStatus.signedOut, null);
  const AuthState.unverified(AppUser user) : this._(AuthStatus.unverified, user);
  const AuthState.signedIn(AppUser user) : this._(AuthStatus.signedIn, user);

  final AuthStatus status;
  final AppUser? user;

  bool get isStaff => user?.isStaff ?? false;

  @override
  List<Object?> get props => [status, user];
}

/// App-wide session state. Drives the router's redirects: signed out →
/// login, unverified → verify email, student → home, staff → staff queue.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._auth) : super(const AuthState.unknown()) {
    _sub = _auth.watchUser().listen(_onUser, onError: (_) => emit(const AuthState.signedOut()));
  }

  final AuthRepository _auth;
  late final StreamSubscription<AppUser?> _sub;

  void _onUser(AppUser? user) {
    if (user == null) return emit(const AuthState.signedOut());
    emit(user.emailVerified ? AuthState.signedIn(user) : AuthState.unverified(user));
  }

  /// Returns true when the email is now verified.
  Future<bool> checkVerified() async {
    try {
      return await _auth.reloadUser();
    } on RepositoryException {
      return false;
    }
  }

  Future<void> resendVerification() => _auth.sendVerificationEmail();

  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }
}
