import 'package:equatable/equatable.dart';

/// Role stored on `users/{uid}.role`. [value] is the Firestore string.
enum UserRole {
  student('student', 'Student'),
  staff('staff', 'Staff');

  const UserRole(this.value, this.label);

  final String value;
  final String label;

  static UserRole fromValue(String? value) => UserRole.values
      .firstWhere((r) => r.value == value, orElse: () => student);
}

/// The signed-in user, combining Firebase Auth state with the
/// `users/{uid}` profile document.
class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.emailVerified,
    this.department,
    this.createdAt,
  });

  final String uid;
  final String email;
  final String displayName;
  final UserRole role;

  /// From Firebase Auth. Unverified users are kept on the verify screen.
  final bool emailVerified;
  final String? department;
  final DateTime? createdAt;

  bool get isStaff => role == UserRole.staff;

  /// Up to two initials for the avatar, e.g. "Amina Hassan" -> "AH".
  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    final letters = parts.where((p) => p.isNotEmpty).take(2).map((p) => p[0]);
    final result = letters.join().toUpperCase();
    return result.isEmpty ? '?' : result;
  }

  AppUser copyWith({bool? emailVerified, String? displayName}) => AppUser(
        uid: uid,
        email: email,
        displayName: displayName ?? this.displayName,
        role: role,
        emailVerified: emailVerified ?? this.emailVerified,
        department: department,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [uid, email, displayName, role, emailVerified, department, createdAt];
}
