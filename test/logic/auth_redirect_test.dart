import 'package:campus_incident_app/core/router/app_router.dart';
import 'package:campus_incident_app/logic/auth/auth_cubit.dart';
import 'package:campus_incident_app/models/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

AppUser _user({UserRole role = UserRole.student, bool verified = true}) => AppUser(
      uid: 'u1',
      email: 'a@alustudent.com',
      displayName: 'Amina Hassan',
      role: role,
      emailVerified: verified,
    );

void main() {
  group('authRedirect', () {
    test('unknown session waits on the splash screen', () {
      expect(authRedirect(const AuthState.unknown(), Routes.home), Routes.splash);
      expect(authRedirect(const AuthState.unknown(), Routes.splash), isNull);
    });

    test('signed-out users can only reach login and register', () {
      const s = AuthState.signedOut();
      expect(authRedirect(s, Routes.home), Routes.login);
      expect(authRedirect(s, Routes.staffQueue), Routes.login);
      expect(authRedirect(s, Routes.login), isNull);
      expect(authRedirect(s, Routes.register), isNull);
    });

    test('unverified users are held on the verify screen', () {
      final s = AuthState.unverified(_user(verified: false));
      expect(authRedirect(s, Routes.home), Routes.verify);
      expect(authRedirect(s, Routes.newReport), Routes.verify);
      expect(authRedirect(s, Routes.verify), isNull);
    });

    test('students land on home and cannot open staff routes', () {
      final s = AuthState.signedIn(_user());
      expect(authRedirect(s, Routes.login), Routes.home);
      expect(authRedirect(s, Routes.staffQueue), Routes.home);
      expect(authRedirect(s, Routes.newReport), isNull);
      expect(authRedirect(s, Routes.incident('i1')), isNull);
    });

    test('staff land on the queue and cannot open student-only routes', () {
      final s = AuthState.signedIn(_user(role: UserRole.staff));
      expect(authRedirect(s, Routes.splash), Routes.staffQueue);
      expect(authRedirect(s, Routes.home), Routes.staffQueue);
      expect(authRedirect(s, Routes.newReport), Routes.staffQueue);
      expect(authRedirect(s, Routes.editIncident('i1')), Routes.staffQueue);
      expect(authRedirect(s, Routes.incident('i1')), isNull);
    });
  });
}
