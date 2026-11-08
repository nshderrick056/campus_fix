import 'package:bloc_test/bloc_test.dart';
import 'package:campus_incident_app/dev/fake_backend.dart';
import 'package:campus_incident_app/logic/auth/auth_cubit.dart';
import 'package:campus_incident_app/logic/auth/auth_form_cubit.dart';
import 'package:campus_incident_app/logic/form_status.dart';
import 'package:campus_incident_app/logic/incidents/incident_detail_cubit.dart';
import 'package:campus_incident_app/logic/incidents/incidents_cubit.dart';
import 'package:campus_incident_app/logic/incidents/report_form_cubit.dart';
import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/models/incident_category.dart';
import 'package:campus_incident_app/models/incident_status.dart';
import 'package:flutter_test/flutter_test.dart';

const student = AppUser(
    uid: 'u-amina', email: 'amina.hassan@alustudent.com', displayName: 'Amina Hassan', role: UserRole.student, emailVerified: true);
const staff = AppUser(
    uid: 'u-jean', email: 'jean.mugisha@alueducation.com', displayName: 'Jean Mugisha', role: UserRole.staff, emailVerified: true);

void main() {
  group('IncidentsCubit', () {
    test('loads the seeded list and applies search, status and scope', () async {
      final backend = createFakeBackend(latency: Duration.zero);
      final cubit = IncidentsCubit(backend.incidents);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, LoadStatus.loaded);
      expect(cubit.state.visible(student.uid), hasLength(5));

      cubit.search('water');
      expect(cubit.state.visible(student.uid).map((i) => i.title), ['Water shortage']);

      cubit
        ..clearFilters()
        ..filterStatus(IncidentStatus.submitted);
      expect(cubit.state.visible(student.uid).every((i) => i.status == IncidentStatus.submitted), isTrue);

      cubit
        ..clearFilters()
        ..setScope(IncidentScope.mine);
      expect(cubit.state.visible(student.uid).every((i) => i.reporterId == student.uid), isTrue);

      cubit
        ..setScope(IncidentScope.all)
        ..filterCategory(IncidentCategory.furniture);
      expect(cubit.state.visible(student.uid), hasLength(1));
      await cubit.close();
    });
  });

  group('ReportFormCubit', () {
    test('requires a category before submitting', () async {
      final backend = createFakeBackend(latency: Duration.zero);
      final cubit = ReportFormCubit(backend.incidents, reporter: student);
      await cubit.submit(formValid: true, title: 'Broken door', description: 'The main door does not close.', location: 'Block A');
      expect(cubit.state.showCategoryError, isTrue);
      expect(cubit.state.status, FormStatus.idle);
    });

    blocTest<ReportFormCubit, ReportFormState>(
      'submits a new report and exposes its id',
      build: () => ReportFormCubit(createFakeBackend(latency: Duration.zero).incidents, reporter: student),
      act: (c) async {
        c.selectCategory(IncidentCategory.facilities);
        await c.submit(formValid: true, title: 'Broken door', description: 'The main door does not close.', location: 'Block A');
      },
      skip: 1,
      expect: () => [
        isA<ReportFormState>().having((s) => s.status, 'status', FormStatus.submitting),
        isA<ReportFormState>()
            .having((s) => s.status, 'status', FormStatus.success)
            .having((s) => s.createdId, 'createdId', isNotNull),
      ],
    );
  });

  group('IncidentDetailCubit', () {
    test('staff status update appends history and notifies the reporter', () async {
      final backend = createFakeBackend(latency: Duration.zero);
      final cubit = IncidentDetailCubit(backend.incidents, 'i4');
      await Future<void>.delayed(Duration.zero);
      final before = cubit.state.incident!.statusHistory.length;

      await cubit.updateStatus(IncidentStatus.inProgress, staff: staff, note: 'Electrician on the way');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.action, FormStatus.success);
      expect(cubit.state.incident!.status, IncidentStatus.inProgress);
      expect(cubit.state.incident!.statusHistory, hasLength(before + 1));
      expect(cubit.state.incident!.statusHistory.last.note, 'Electrician on the way');
      final alerts = await backend.notifications.watchFor('u-other').first;
      expect(alerts.first.status, IncidentStatus.inProgress);
      await cubit.close();
    });

    test('a student cannot change status', () async {
      final backend = createFakeBackend(latency: Duration.zero);
      final cubit = IncidentDetailCubit(backend.incidents, 'i4');
      await cubit.updateStatus(IncidentStatus.resolved, staff: student);
      expect(cubit.state.action, FormStatus.failure);
      await cubit.close();
    });
  });

  group('Auth', () {
    test('rejects non-ALU emails and signs in ALU users', () async {
      final backend = createFakeBackend(latency: Duration.zero);
      final auth = AuthCubit(backend.auth);
      final form = AuthFormCubit(backend.auth);

      await form.signIn('amina@gmail.com', 'password');
      expect(form.state.status, FormStatus.failure);

      await form.signIn('amina.hassan@alustudent.com', 'password');
      await Future<void>.delayed(Duration.zero);
      expect(auth.state.status, AuthStatus.signedIn);
      expect(auth.state.isStaff, isFalse);
      await auth.close();
    });

    test('Google sign-in signs the user straight in (already verified)', () async {
      final backend = createFakeBackend(latency: Duration.zero);
      final auth = AuthCubit(backend.auth);
      await AuthFormCubit(backend.auth).signInWithGoogle();
      await Future<void>.delayed(Duration.zero);
      expect(auth.state.status, AuthStatus.signedIn);
      await auth.close();
    });

    test('new accounts start unverified as students', () async {
      final backend = createFakeBackend(latency: Duration.zero);
      final auth = AuthCubit(backend.auth);
      await AuthFormCubit(backend.auth).register('New Student', 'new.student@alustudent.com', 'password1');
      await Future<void>.delayed(Duration.zero);
      expect(auth.state.status, AuthStatus.unverified);
      expect(auth.state.user!.role, UserRole.student);

      expect(await auth.checkVerified(), isTrue);
      await Future<void>.delayed(Duration.zero);
      expect(auth.state.status, AuthStatus.signedIn);
      await auth.close();
    });
  });
}
