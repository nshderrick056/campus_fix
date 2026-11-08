import 'package:campus_incident_app/data/firebase/firestore_mappers.dart';
import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/models/incident_category.dart';
import 'package:campus_incident_app/models/incident_draft.dart';
import 'package:campus_incident_app/models/incident_status.dart';
import 'package:campus_incident_app/models/status_change.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime(2026, 11, 1, 9, 30);
  const reporter = AppUser(
    uid: 'u1',
    email: 'amina@alustudent.com',
    displayName: 'Amina Hassan',
    role: UserRole.student,
    emailVerified: true,
  );
  const draft = IncidentDraft(
    title: '  Leaking tap ',
    description: 'Tap in block B',
    category: IncidentCategory.water,
    location: 'Block B',
    isAnonymous: true,
  );

  test('Timestamp <-> DateTime', () {
    expect(dateFrom(Timestamp.fromDate(t0)), t0);
    expect(timestampFrom(t0).toDate(), t0);
    expect(optionalDateFrom(null), isNull);
  });

  test('StatusChange round-trips', () {
    final change = StatusChange(
      status: IncidentStatus.inProgress,
      changedBy: 's1',
      changedByName: 'Jean',
      at: t0,
      note: 'On it',
    );
    final map = statusChangeToMap(change);
    expect(map['status'], 'in_progress');
    expect(map['at'], isA<Timestamp>());
    expect(statusChangeFromMap(map), change);
  });

  test('new incident map uses enum values and a first history entry', () {
    final map = newIncidentToMap(
      draft: draft,
      reporter: reporter,
      now: t0,
      photoUrl: 'https://res.cloudinary.com/x/image/upload/a.jpg',
      photoPublicId: 'campus_incidents/a',
    );
    expect(map['title'], 'Leaking tap');
    expect(map['category'], 'water');
    expect(map['status'], 'submitted');
    expect(map['reporterId'], 'u1');
    expect(map['statusHistory'], hasLength(1));

    final incident = incidentFromMap('i1', map);
    expect(incident.id, 'i1');
    expect(incident.category, IncidentCategory.water);
    expect(incident.status, IncidentStatus.submitted);
    expect(incident.isAnonymous, isTrue);
    expect(incident.createdAt, t0);
    expect(incident.hasPhoto, isTrue);
    expect(incident.statusHistory.single.changedByName, 'Amina Hassan');
  });

  test('incidentFromMap sorts history oldest first and tolerates gaps', () {
    final incident = incidentFromMap('i2', {
      'title': 'X',
      'status': 'resolved',
      'category': 'nonsense',
      'createdAt': Timestamp.fromDate(t0),
      'statusHistory': [
        {'status': 'resolved', 'at': Timestamp.fromDate(t0.add(const Duration(hours: 2)))},
        {'status': 'submitted', 'at': Timestamp.fromDate(t0)},
      ],
    });
    expect(incident.category, IncidentCategory.other);
    expect(incident.updatedAt, t0);
    expect(incident.photoUrl, isNull);
    expect(incident.statusHistory.map((c) => c.status),
        [IncidentStatus.submitted, IncidentStatus.resolved]);
  });

  test('appUserFrom prefers the profile and defaults to student', () {
    final withProfile = appUserFrom(
      uid: 'u1',
      email: 'jean@alueducation.com',
      emailVerified: true,
      profile: {'name': 'Jean M', 'role': 'staff', 'createdAt': Timestamp.fromDate(t0)},
    );
    expect(withProfile.isStaff, isTrue);
    expect(withProfile.displayName, 'Jean M');
    expect(withProfile.createdAt, t0);

    final noProfile = appUserFrom(
      uid: 'u2',
      email: 'new.student@alustudent.com',
      emailVerified: false,
    );
    expect(noProfile.role, UserRole.student);
    expect(noProfile.displayName, 'new.student');
  });

  test('new user profile is always a student', () {
    final map = newUserProfileToMap(name: ' Amina ', email: 'Amina@ALUstudent.com', now: t0);
    expect(map, {
      'name': 'Amina',
      'email': 'amina@alustudent.com',
      'role': 'student',
      'createdAt': Timestamp.fromDate(t0),
    });
  });

  test('notification round-trips and drops blank notes', () {
    final map = notificationToMap(
      incidentId: 'i1',
      incidentTitle: 'Leaking tap',
      status: IncidentStatus.resolved,
      now: t0,
      note: '  ',
    );
    expect(map.containsKey('note'), isFalse);
    expect(map['read'], isFalse);
    final n = notificationFromMap('n1', map);
    expect(n.status, IncidentStatus.resolved);
    expect(n.createdAt, t0);
    expect(n.read, isFalse);
  });
}
