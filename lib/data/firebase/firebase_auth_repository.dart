import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/constants/app_constants.dart';
import '../../models/app_user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/repository_exception.dart';
import 'firebase_errors.dart';
import 'firestore_mappers.dart';

/// [AuthRepository] backed by Firebase Auth + the `users/{uid}` profile doc.
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required this._auth,
    required FirebaseFirestore firestore,
  }) : _users = firestore.collection(AppConstants.usersCollection);

  final FirebaseAuth _auth;
  final CollectionReference<Json> _users;

  /// Fires after [reloadUser] so [watchUser] re-emits the fresh
  /// `emailVerified` flag (authStateChanges does not fire on reload).
  final _refresh = StreamController<void>.broadcast();

  AppUser? _current;

  @override
  AppUser? get currentUser => _current;

  static bool isAllowedEmail(String email) {
    final e = email.trim().toLowerCase();
    return e.endsWith('@${AppConstants.studentEmailDomain}') ||
        e.endsWith('@${AppConstants.staffEmailDomain}');
  }

  static void _checkDomain(String email) {
    if (!isAllowedEmail(email)) {
      throw const RepositoryException(
        'email-not-allowed',
        'Only @${AppConstants.studentEmailDomain} or '
            '@${AppConstants.staffEmailDomain} emails are accepted.',
      );
    }
  }

  @override
  Stream<AppUser?> watchUser() {
    late final StreamController<AppUser?> controller;
    StreamSubscription<User?>? authSub;
    StreamSubscription<DocumentSnapshot<Json>>? profileSub;
    StreamSubscription<void>? refreshSub;
    Json? profile;

    void emit() {
      final user = _auth.currentUser;
      _current = user == null
          ? null
          : appUserFrom(
              uid: user.uid,
              email: user.email ?? '',
              emailVerified: user.emailVerified,
              authDisplayName: user.displayName,
              profile: profile,
            );
      controller.add(_current);
    }

    void onError(Object e) => controller.addError(mapFirebaseError(e));

    controller = StreamController<AppUser?>(
      onListen: () {
        authSub = _auth.authStateChanges().listen((user) {
          profileSub?.cancel();
          profileSub = null;
          profile = null;
          if (user == null) {
            emit();
            return;
          }
          profileSub = _users.doc(user.uid).snapshots().listen(
            (snap) {
              profile = snap.data();
              emit();
            },
            // e.g. permission-denied before verification: still emit the
            // auth user so the UI can show the verify screen.
            onError: (Object _) => emit(),
          );
        }, onError: onError);
        refreshSub = _refresh.stream.listen((_) => emit());
      },
      onCancel: () async {
        await authSub?.cancel();
        await profileSub?.cancel();
        await refreshSub?.cancel();
      },
    );
    return controller.stream;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    _checkDomain(email);
    await guard(() => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ));
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _checkDomain(email);
    await guard(() async {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;
      await user.updateDisplayName(name.trim());
      // Role is always "student"; staff are promoted in the Firebase console.
      await _users.doc(user.uid).set(newUserProfileToMap(
            name: name,
            email: email,
            now: DateTime.now(),
          ));
      await user.sendEmailVerification();
      _refresh.add(null);
    });
  }

  @override
  Future<void> signInWithGoogle() => guard(() async {
        final provider = GoogleAuthProvider()
          ..setCustomParameters({'prompt': 'select_account'});
        final cred = kIsWeb
            ? await _auth.signInWithPopup(provider)
            : await _auth.signInWithProvider(provider);
        final user = cred.user!;
        final email = user.email ?? '';
        if (!isAllowedEmail(email)) {
          // Remove the account Firebase just created for the non-ALU Google user.
          await user.delete();
          _checkDomain(email);
        }
        final doc = _users.doc(user.uid);
        if (!(await doc.get()).exists) {
          await doc.set(newUserProfileToMap(
            name: user.displayName ?? email.split('@').first,
            email: email,
            now: DateTime.now(),
          ));
        }
        _refresh.add(null);
      });

  @override
  Future<void> sendVerificationEmail() => guard(() async {
        final user = _requireUser();
        await user.sendEmailVerification();
      });

  @override
  Future<bool> reloadUser() => guard(() async {
        final user = _requireUser();
        await user.reload();
        // Refresh the ID token so security rules see email_verified = true.
        await _auth.currentUser?.getIdToken(true);
        _refresh.add(null);
        return _auth.currentUser?.emailVerified ?? false;
      });

  @override
  Future<void> sendPasswordReset(String email) async {
    _checkDomain(email);
    await guard(() => _auth.sendPasswordResetEmail(email: email.trim()));
  }

  @override
  Future<void> signOut() => guard(_auth.signOut);

  User _requireUser() =>
      _auth.currentUser ??
      (throw const RepositoryException(
          'not-signed-in', 'Please sign in again.'));
}
