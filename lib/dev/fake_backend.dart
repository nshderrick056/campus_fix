import 'dart:async';

import '../core/constants/app_constants.dart';
import '../data/backend.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/incident_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/repositories/repository_exception.dart';
import '../models/app_notification.dart';
import '../models/app_user.dart';
import '../models/incident.dart';
import '../models/incident_category.dart';
import '../models/incident_draft.dart';
import '../models/incident_status.dart';
import '../models/status_change.dart';

/// In-memory backend for building and testing the UI without Firebase.
/// Run with `flutter run --dart-define=FAKE_BACKEND=true`.
///
/// Demo accounts (any password of 6+ characters):
/// - amina.hassan@alustudent.com (student)
/// - jean.mugisha@alueducation.com (staff)
Backend createFakeBackend({bool seed = true, Duration latency = const Duration(milliseconds: 350)}) {
  final store = FakeStore(latency);
  if (seed) store.seed();
  return Backend(
    auth: FakeAuthRepository(store),
    incidents: FakeIncidentRepository(store),
    notifications: FakeNotificationRepository(store),
  );
}

class FakeStore {
  FakeStore(this.latency);

  final Duration latency;
  final users = <String, AppUser>{};
  final passwords = <String, String>{};
  final incidents = <String, Incident>{};
  final notifications = <String, List<AppNotification>>{};
  final _changes = StreamController<void>.broadcast();
  int _nextId = 1;

  String newId(String prefix) => '$prefix${_nextId++}';
  Future<void> delay() => Future<void>.delayed(latency);
  void changed() => _changes.add(null);

  /// A stream that re-evaluates [read] on every change.
  Stream<T> watch<T>(T Function() read) async* {
    yield read();
    await for (final _ in _changes.stream) {
      yield read();
    }
  }

  void seed() {
    final now = DateTime.now();
    final amina = AppUser(
      uid: 'u-amina',
      email: 'amina.hassan@alustudent.com',
      displayName: 'Amina Hassan',
      role: UserRole.student,
      emailVerified: true,
      department: 'Computer Science',
      createdAt: now.subtract(const Duration(days: 30)),
    );
    final jean = AppUser(
      uid: 'u-jean',
      email: 'jean.mugisha@alueducation.com',
      displayName: 'Jean Mugisha',
      role: UserRole.staff,
      emailVerified: true,
      department: 'Facilities Office',
      createdAt: now.subtract(const Duration(days: 300)),
    );
    for (final u in [amina, jean]) {
      users[u.uid] = u;
      passwords[u.email] = 'password';
    }

    Incident make(
      String id,
      String title,
      String description,
      IncidentCategory category,
      String location,
      Duration age, {
      List<(IncidentStatus, Duration, String?)> later = const [],
      String reporterId = 'u-amina',
      String reporterName = 'Amina Hassan',
      bool anonymous = false,
    }) {
      final created = now.subtract(age);
      final history = <StatusChange>[
        StatusChange(status: IncidentStatus.submitted, changedBy: reporterId, changedByName: reporterName, at: created),
        for (final (s, after, note) in later)
          StatusChange(status: s, changedBy: jean.uid, changedByName: jean.displayName, at: created.add(after), note: note),
      ];
      return Incident(
        id: id,
        title: title,
        description: description,
        category: category,
        location: location,
        status: history.last.status,
        reporterId: reporterId,
        reporterName: reporterName,
        isAnonymous: anonymous,
        createdAt: created,
        updatedAt: history.last.at,
        statusHistory: history,
      );
    }

    for (final i in [
      make('i1', 'Water shortage', 'There has been no water supply in the student residence since this morning. It affects everyone on the 2nd floor.',
          IncidentCategory.water, 'Student Residence — 2nd floor', const Duration(hours: 2),
          later: [(IncidentStatus.inProgress, const Duration(hours: 1), 'Plumber assigned by the Facilities Office.')]),
      make('i2', 'Broken classroom projector', 'The projector in Room 204 does not turn on. Lectures are affected.',
          IncidentCategory.itWifi, 'Block B — Room 204', const Duration(days: 1),
          later: [(IncidentStatus.inProgress, const Duration(hours: 5), null)]),
      make('i3', 'Overflowing bin', 'The bin near the cafeteria entrance has not been emptied for two days.',
          IncidentCategory.sanitation, 'Cafeteria', const Duration(days: 3),
          later: [(IncidentStatus.inProgress, const Duration(hours: 3), null), (IncidentStatus.resolved, const Duration(days: 1), 'Bin emptied; daily schedule restored.')]),
      make('i4', 'Exposed wiring near stairwell', 'Wires are hanging from the ceiling light near the ground-floor stairs.',
          IncidentCategory.electricity, 'Block A — Ground floor', const Duration(minutes: 35),
          reporterId: 'u-other', reporterName: 'Kevin Otieno', anonymous: true),
      make('i5', 'Broken chair in library', 'One of the study chairs on level 2 has a broken leg.',
          IncidentCategory.furniture, 'Library — Level 2', const Duration(hours: 5),
          reporterId: 'u-other2', reporterName: 'Grace Uwase'),
    ]) {
      incidents[i.id] = i;
    }

    notifications['u-amina'] = [
      AppNotification(id: 'n1', incidentId: 'i1', incidentTitle: 'Water shortage', status: IncidentStatus.inProgress,
          createdAt: now.subtract(const Duration(hours: 1)), read: false, note: 'Plumber assigned by the Facilities Office.'),
      AppNotification(id: 'n2', incidentId: 'i3', incidentTitle: 'Overflowing bin', status: IncidentStatus.resolved,
          createdAt: now.subtract(const Duration(days: 2)), read: true),
    ];
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._s);

  final FakeStore _s;
  String? _uid;

  @override
  AppUser? get currentUser => _uid == null ? null : _s.users[_uid];

  @override
  Stream<AppUser?> watchUser() => _s.watch(() => currentUser);

  void _checkDomain(String email) {
    final domain = email.split('@').last.toLowerCase();
    if (domain != AppConstants.studentEmailDomain && domain != AppConstants.staffEmailDomain) {
      throw const RepositoryException('email-not-allowed', 'Only @alustudent.com or @alueducation.com emails are accepted.');
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _s.delay();
    final e = email.trim().toLowerCase();
    _checkDomain(e);
    final user = _s.users.values.where((u) => u.email == e).firstOrNull;
    // Demo rule: any password of 6+ characters works for an existing account.
    if (user == null || password.length < 6) {
      throw const RepositoryException('wrong-credentials', 'Incorrect email or password.');
    }
    _uid = user.uid;
    _s.changed();
  }

  @override
  Future<void> register({required String name, required String email, required String password}) async {
    await _s.delay();
    final e = email.trim().toLowerCase();
    _checkDomain(e);
    if (_s.users.values.any((u) => u.email == e)) {
      throw const RepositoryException('email-in-use', 'An account with this email already exists.');
    }
    final user = AppUser(uid: _s.newId('u'), email: e, displayName: name.trim(), role: UserRole.student,
        emailVerified: false, createdAt: DateTime.now());
    _s.users[user.uid] = user;
    _s.passwords[e] = password;
    _uid = user.uid;
    _s.changed();
  }

  /// In the fake, "Google" signs in the demo student.
  @override
  Future<void> signInWithGoogle() async {
    await _s.delay();
    _uid = 'u-amina';
    _s.changed();
  }

  @override
  Future<void> sendVerificationEmail() => _s.delay();

  /// In the fake, "reloading" marks the email as verified so the flow can be
  /// demonstrated end to end.
  @override
  Future<bool> reloadUser() async {
    await _s.delay();
    final u = currentUser;
    if (u == null) return false;
    _s.users[u.uid] = u.copyWith(emailVerified: true);
    _s.changed();
    return true;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _s.delay();
    _checkDomain(email.trim().toLowerCase());
  }

  @override
  Future<void> signOut() async {
    _uid = null;
    _s.changed();
  }
}

class FakeIncidentRepository implements IncidentRepository {
  FakeIncidentRepository(this._s);

  final FakeStore _s;

  List<Incident> _sorted(Iterable<Incident> items) =>
      items.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Stream<List<Incident>> watchAll() => _s.watch(() => _sorted(_s.incidents.values));

  @override
  Stream<List<Incident>> watchByReporter(String uid) =>
      _s.watch(() => _sorted(_s.incidents.values.where((i) => i.reporterId == uid)));

  @override
  Stream<Incident?> watchOne(String id) => _s.watch(() => _s.incidents[id]);

  @override
  Future<String> create(IncidentDraft draft, {required AppUser reporter}) async {
    await _s.delay();
    final now = DateTime.now();
    final id = _s.newId('i');
    _s.incidents[id] = Incident(
      id: id,
      title: draft.title.trim(),
      description: draft.description.trim(),
      category: draft.category,
      location: draft.location.trim(),
      status: IncidentStatus.submitted,
      reporterId: reporter.uid,
      reporterName: reporter.displayName,
      isAnonymous: draft.isAnonymous,
      createdAt: now,
      updatedAt: now,
      // The fake keeps the local file path so the UI can show the photo.
      photoUrl: draft.photo?.path,
      statusHistory: [
        StatusChange(status: IncidentStatus.submitted, changedBy: reporter.uid, changedByName: reporter.displayName, at: now),
      ],
    );
    _s.changed();
    return id;
  }

  Incident _require(String id) =>
      _s.incidents[id] ?? (throw const RepositoryException('not-found', 'This report no longer exists.'));

  @override
  Future<void> update(String id, IncidentDraft draft) async {
    await _s.delay();
    final old = _require(id);
    if (!old.status.isEditableByReporter) {
      throw const RepositoryException('locked', 'Reports cannot be edited once staff start working on them.');
    }
    _s.incidents[id] = Incident(
      id: id,
      title: draft.title.trim(),
      description: draft.description.trim(),
      category: draft.category,
      location: draft.location.trim(),
      status: old.status,
      reporterId: old.reporterId,
      reporterName: old.reporterName,
      isAnonymous: draft.isAnonymous,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
      photoUrl: draft.removePhoto ? null : (draft.photo?.path ?? old.photoUrl),
      statusHistory: old.statusHistory,
    );
    _s.changed();
  }

  @override
  Future<void> delete(String id) async {
    await _s.delay();
    if (!_require(id).status.isEditableByReporter) {
      throw const RepositoryException('locked', 'Reports cannot be deleted once staff start working on them.');
    }
    _s.incidents.remove(id);
    _s.changed();
  }

  @override
  Future<void> updateStatus(String id, {required IncidentStatus status, required AppUser staff, String? note}) async {
    await _s.delay();
    if (!staff.isStaff) {
      throw const RepositoryException('permission-denied', 'Only staff can update a report status.');
    }
    final old = _require(id);
    final now = DateTime.now();
    final cleanNote = (note == null || note.trim().isEmpty) ? null : note.trim();
    _s.incidents[id] = Incident(
      id: id,
      title: old.title,
      description: old.description,
      category: old.category,
      location: old.location,
      status: status,
      reporterId: old.reporterId,
      reporterName: old.reporterName,
      isAnonymous: old.isAnonymous,
      createdAt: old.createdAt,
      updatedAt: now,
      photoUrl: old.photoUrl,
      photoPublicId: old.photoPublicId,
      statusHistory: [
        ...old.statusHistory,
        StatusChange(status: status, changedBy: staff.uid, changedByName: staff.displayName, at: now, note: cleanNote),
      ],
    );
    (_s.notifications[old.reporterId] ??= []).insert(
      0,
      AppNotification(id: _s.newId('n'), incidentId: id, incidentTitle: old.title, status: status,
          createdAt: now, read: false, note: cleanNote),
    );
    _s.changed();
  }
}

class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository(this._s);

  final FakeStore _s;

  @override
  Stream<List<AppNotification>> watchFor(String uid) =>
      _s.watch(() => List.unmodifiable(_s.notifications[uid] ?? const <AppNotification>[]));

  AppNotification _asRead(AppNotification n) => AppNotification(
      id: n.id, incidentId: n.incidentId, incidentTitle: n.incidentTitle, status: n.status,
      createdAt: n.createdAt, read: true, note: n.note);

  @override
  Future<void> markRead(String uid, String notificationId) async {
    final list = _s.notifications[uid];
    if (list == null) return;
    _s.notifications[uid] = [for (final n in list) n.id == notificationId ? _asRead(n) : n];
    _s.changed();
  }

  @override
  Future<void> markAllRead(String uid) async {
    final list = _s.notifications[uid];
    if (list == null) return;
    _s.notifications[uid] = [for (final n in list) _asRead(n)];
    _s.changed();
  }
}
