import 'package:campus_incident_app/data/firebase/firebase_auth_repository.dart';
import 'package:campus_incident_app/data/firebase/firebase_errors.dart';
import 'package:campus_incident_app/data/repositories/repository_exception.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements FirebaseAuth {}

void main() {
  late _MockAuth auth;
  late FirebaseAuthRepository repo;

  setUp(() {
    auth = _MockAuth();
    repo = FirebaseAuthRepository(auth: auth, firestore: FakeFirebaseFirestore());
  });

  test('only ALU emails are allowed', () {
    expect(FirebaseAuthRepository.isAllowedEmail('a@alustudent.com'), isTrue);
    expect(FirebaseAuthRepository.isAllowedEmail(' Jean@ALUEducation.com '), isTrue);
    expect(FirebaseAuthRepository.isAllowedEmail('a@gmail.com'), isFalse);
    expect(FirebaseAuthRepository.isAllowedEmail('a@alustudent.com.evil.io'), isFalse);
  });

  test('non-ALU emails are rejected before Firebase is called', () async {
    final notAllowed =
        isA<RepositoryException>().having((e) => e.code, 'code', 'email-not-allowed');

    await expectLater(repo.signIn(email: 'x@gmail.com', password: 'secret1'), throwsA(notAllowed));
    await expectLater(
      repo.register(name: 'X', email: 'x@gmail.com', password: 'secret1'),
      throwsA(notAllowed),
    );
    await expectLater(repo.sendPasswordReset('x@gmail.com'), throwsA(notAllowed));
    verifyZeroInteractions(auth);
  });

  test('auth error codes become friendly RepositoryExceptions', () async {
    when(() => auth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(code: 'invalid-credential'));

    await expectLater(
      repo.signIn(email: 'a@alustudent.com', password: 'wrong12'),
      throwsA(isA<RepositoryException>()
          .having((e) => e.code, 'code', 'wrong-credentials')
          .having((e) => e.message, 'message', 'Incorrect email or password.')),
    );

    expect(mapFirebaseError(FirebaseAuthException(code: 'email-already-in-use')).code,
        'email-in-use');
    expect(mapFirebaseError(FirebaseAuthException(code: 'network-request-failed')).code,
        'network');
    expect(mapFirebaseError(StateError('boom')).code, 'unknown');
  });
}
