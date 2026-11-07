import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Incident categories. [value] is what is stored in Firestore.
enum IncidentCategory {
  facilities('facilities', 'Facilities', Symbols.apartment_rounded),
  water('water', 'Water', Symbols.water_drop_rounded),
  electricity('electricity', 'Electricity', Symbols.bolt_rounded),
  safety('safety', 'Safety', Symbols.shield_rounded),
  sanitation('sanitation', 'Sanitation', Symbols.delete_rounded),
  furniture('furniture', 'Furniture', Symbols.chair_rounded),
  itWifi('it_wifi', 'IT & Wi-Fi', Symbols.wifi_rounded),
  other('other', 'Other', Symbols.more_horiz_rounded);

  const IncidentCategory(this.value, this.label, this.icon);

  final String value;
  final String label;
  final IconData icon;

  static IncidentCategory fromValue(String value) => IncidentCategory.values
      .firstWhere((c) => c.value == value, orElse: () => other);
}
