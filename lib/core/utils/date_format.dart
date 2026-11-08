import 'package:intl/intl.dart';

/// "just now", "35m ago", "2h ago", "3d ago", then "Oct 15".
String relativeTime(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('MMM d').format(time);
}

/// "Oct 15, 2026 · 10:24 AM"
String fullDateTime(DateTime time) => DateFormat("MMM d, y '·' h:mm a").format(time);

/// "Oct 15 · 10:24 AM"
String shortDateTime(DateTime time) => DateFormat("MMM d '·' h:mm a").format(time);

/// "Good morning" / "Good afternoon" / "Good evening"
String greeting([DateTime? now]) {
  final h = (now ?? DateTime.now()).hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}
