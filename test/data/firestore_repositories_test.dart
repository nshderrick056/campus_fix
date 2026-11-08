import 'dart:io';

import 'package:campus_incident_app/data/firebase/firestore_incident_repository.dart';
import 'package:campus_incident_app/data/firebase/firestore_notification_repository.dart';
import 'package:campus_incident_app/data/repositories/repository_exception.dart';
import 'package:campus_incident_app/data/services/photo_storage_service.dart';
import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/models/incident_category.dart';
import 'package:campus_incident_app/models/incident_draft.dart';
import 'package:campus_incident_app/models/incident_status.dart';
import 'package:campus_incident_app/models/uploaded_photo.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePhotos implements PhotoStorageService {
  int uploads = 0;
  bool fail = false;

  @override
  Future<UploadedPhoto> uploadPhoto(File file) async {
    if (fail) throw const PhotoUploadException('Upload broke');
    uploads++;
    return UploadedPhoto(
      url: 'https://res.cloudinary.com/demo/image/upload/p$uploads.jpg',
      publicId: 'campus_incidents/p$uploads',
    );
  }

  @override
  String thumbnailUrl(String url, {int width = 400}) => url;
}

const student = AppUser(
  uid: 'u-amina',
  email: 'amina@alustudent.com',
  displayName: 'Amina Hassan',
  role: UserRole.student,
  emailVerified: true,
);
const staff = AppUser(
  uid: 's-jean',
  email: 'jean@alueducation.com',
  displayName: 'Jean Mugisha',
  role: UserRole.staff,
  emailVerified: true,
);

IncidentDraft draft(String title, {File? photo, bool removePhoto = false}) =>
    IncidentDraft(
      title: title,
      description: 'Details',
      category: IncidentCategory.electricity,
      location: 'Library',
      photo: photo,
      removePhoto: removePhoto,
    );

void main() {
  late FakeFirebaseFirestore db;
  late _FakePhotos photos;
  late FirestoreIncidentRepository incidents;
  late FirestoreNotificationRepository notifications;
  late DateTime now;

  setUp(() {
    db = FakeFirebaseFirestore();
    photos = _FakePhotos();
    now = DateTime(2026, 11, 1, 8);
    incidents = FirestoreIncidentRepository(
      firestore: db,
      photos: photos,
      // Each call is one minute later, so ordering is deterministic.
      clock: () => now = now.add(const Duration(minutes: 1)),
    );
    notifications = FirestoreNotificationRepository(firestore: db);
  });

  group('FirestoreIncidentRepository', () {
    test('create then watchByReporter returns newest first', () async {
      final first = await incidents.create(draft('Flickering light'), reporter: student);
      final second = await incidents.create(draft('Dead socket'), reporter: student);
      await incidents.create(draft('Other person'),
          reporter: staff); // different reporter

      final mine = await incidents.watchByReporter(student.uid).first;
      expect(mine.map((i) => i.id), [second, first]);

      final created = mine.last;
      expect(created.status, IncidentStatus.submitted);
      expect(created.reporterName, 'Amina Hassan');
      expect(created.statusHistory.single.status, IncidentStatus.submitted);
      expect(created.statusHistory.single.changedBy, student.uid);

      expect(await incidents.watchAll().first, hasLength(3));
    });

    test('create uploads the photo first and stores url + public id', () async {
      final id = await incidents.create(draft('With photo', photo: File('x.jpg')),
          reporter: student);
      final incident = (await incidents.watchOne(id).first)!;
      expect(photos.uploads, 1);
      expect(incident.photoUrl, contains('/upload/p1.jpg'));
      expect(incident.photoPublicId, 'campus_incidents/p1');
    });

    test('a failed upload creates nothing', () async {
      photos.fail = true;
      await expectLater(
        incidents.create(draft('Broken', photo: File('x.jpg')), reporter: student),
        throwsA(isA<RepositoryException>()
            .having((e) => e.code, 'code', 'upload-failed')),
      );
      expect(await incidents.watchAll().first, isEmpty);
    });

    test('update edits content and can remove the photo', () async {
      final id = await incidents.create(draft('Old', photo: File('x.jpg')),
          reporter: student);
      await incidents.update(id, draft('New title', removePhoto: true));

      final incident = (await incidents.watchOne(id).first)!;
      expect(incident.title, 'New title');
      expect(incident.photoUrl, isNull);
      expect(incident.status, IncidentStatus.submitted);
    });

    test('updateStatus appends history and notifies the reporter', () async {
      final id = await incidents.create(draft('Flickering light'), reporter: student);

      await incidents.updateStatus(id,
          status: IncidentStatus.inProgress, staff: staff, note: ' Electrician booked ');

      // fake_cloud_firestore can complete runTransaction a tick before the
      // snapshot reflects it, so wait for the update rather than take .first.
      final incident = (await incidents
          .watchOne(id)
          .firstWhere((i) => i?.status == IncidentStatus.inProgress)
          .timeout(const Duration(seconds: 2)))!;
      expect(incident.statusHistory.map((c) => c.status),
          [IncidentStatus.submitted, IncidentStatus.inProgress]);
      expect(incident.statusHistory.last.changedByName, 'Jean Mugisha');
      expect(incident.statusHistory.last.note, 'Electrician booked');

      final alerts = await notifications.watchFor(student.uid).first;
      expect(alerts, hasLength(1));
      expect(alerts.single.incidentId, id);
      expect(alerts.single.incidentTitle, 'Flickering light');
      expect(alerts.single.status, IncidentStatus.inProgress);
      expect(alerts.single.note, 'Electrician booked');
      expect(alerts.single.read, isFalse);
    });

    test('reporter cannot edit or delete once staff picked it up', () async {
      final id = await incidents.create(draft('Locked'), reporter: student);
      await incidents.updateStatus(id, status: IncidentStatus.inProgress, staff: staff);

      final locked = isA<RepositoryException>().having((e) => e.code, 'code', 'locked');
      await expectLater(incidents.update(id, draft('Changed')), throwsA(locked));
      await expectLater(incidents.delete(id), throwsA(locked));
    });

    test('delete while submitted removes it; watchOne then emits null', () async {
      final id = await incidents.create(draft('Oops'), reporter: student);
      await incidents.delete(id);
      expect(await incidents.watchOne(id).first, isNull);
    });

    test('students cannot change status; missing ids are not-found', () async {
      final id = await incidents.create(draft('X'), reporter: student);
      await expectLater(
        incidents.updateStatus(id, status: IncidentStatus.resolved, staff: student),
        throwsA(isA<RepositoryException>()
            .having((e) => e.code, 'code', 'permission-denied')),
      );
      await expectLater(
        incidents.update('missing', draft('Y')),
        throwsA(isA<RepositoryException>().having((e) => e.code, 'code', 'not-found')),
      );
    });
  });

  group('FirestoreNotificationRepository', () {
    test('markRead and markAllRead', () async {
      final a = await incidents.create(draft('A'), reporter: student);
      final b = await incidents.create(draft('B'), reporter: student);
      await incidents.updateStatus(a, status: IncidentStatus.inProgress, staff: staff);
      await incidents.updateStatus(b, status: IncidentStatus.resolved, staff: staff);

      var alerts = await notifications.watchFor(student.uid).first;
      expect(alerts.map((n) => n.incidentTitle), ['B', 'A']); // newest first

      await notifications.markRead(student.uid, alerts.first.id);
      alerts = await notifications.watchFor(student.uid).first;
      expect(alerts.map((n) => n.read), [true, false]);

      await notifications.markAllRead(student.uid);
      alerts = await notifications.watchFor(student.uid).first;
      expect(alerts.every((n) => n.read), isTrue);
    });
  });
}
