import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/repository_exception.dart';
import '../form_status.dart';

class AuthFormState extends Equatable {
  const AuthFormState({this.status = FormStatus.idle, this.error, this.info});

  final FormStatus status;

  /// Message to show when [status] is failure.
  final String? error;

  /// One-off confirmation (e.g. "Reset link sent").
  final String? info;

  bool get isSubmitting => status == FormStatus.submitting;

  @override
  List<Object?> get props => [status, error, info];
}

/// Handles the login and register forms. Navigation after success is done
/// by the router reacting to [AuthCubit], not by this cubit.
class AuthFormCubit extends Cubit<AuthFormState> {
  AuthFormCubit(this._auth) : super(const AuthFormState());

  final AuthRepository _auth;

  Future<void> signIn(String email, String password) =>
      _run(() => _auth.signIn(email: email.trim(), password: password));

  Future<void> signInWithGoogle() => _run(_auth.signInWithGoogle);

  Future<void> register(String name, String email, String password) =>
      _run(() => _auth.register(name: name.trim(), email: email.trim(), password: password));

  Future<void> sendPasswordReset(String email) => _run(
        () => _auth.sendPasswordReset(email.trim()),
        info: 'If an account exists, a reset link is on its way to $email.',
      );

  Future<void> _run(Future<void> Function() action, {String? info}) async {
    if (state.isSubmitting) return;
    emit(const AuthFormState(status: FormStatus.submitting));
    try {
      await action();
      emit(AuthFormState(status: FormStatus.success, info: info));
    } on RepositoryException catch (e) {
      emit(AuthFormState(status: FormStatus.failure, error: e.message));
    } catch (_) {
      emit(const AuthFormState(status: FormStatus.failure, error: 'Something went wrong. Check your connection and try again.'));
    }
  }
}
