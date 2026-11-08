abstract final class AppConstants {
  static const appName = 'CampusFix';

  /// ALU campus photo used behind the sign-in screens and the Home header.
  static const campusPhoto = 'assets/images/auth_hero.webp';

  /// Only ALU accounts may register.
  static const studentEmailDomain = 'alustudent.com';
  static const staffEmailDomain = 'alueducation.com';

  /// Buildings offered in the report form's location picker; the user adds
  /// the room/floor detail separately.
  static const campusLocations = [
    'Block A',
    'Block B',
    'Block C',
    'Library',
    'Cafeteria',
    'Student Residence',
    'Sports Ground',
    'Administration',
    'Parking',
    'Other',
  ];

  /// Firestore collection names.
  static const usersCollection = 'users';
  static const incidentsCollection = 'incidents';
}
